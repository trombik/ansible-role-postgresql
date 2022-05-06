require "spec_helper"
require "serverspec"

package = ""
service = "postgresql"
user    = "postgres"
group   = "postgres"
ports   = [5432]
# version_major = nil
db_dir = nil
conf_dir = nil
extra_packages = []
psycopg2_package = nil
pgsql_users = [
  { name: "root", password: "AdminPassWord" },
  { name: "foo", password: "PassWord" }
]
python_bin = "python3"

case os[:family]
when "freebsd"
  version_major = 13
  db_dir = "/var/db/postgres/data#{version_major}"
  package = "databases/postgresql#{version_major}-server"
  extra_packages = ["databases/postgresql#{version_major}-contrib"]
  conf_dir = db_dir
  psycopg2_package = "databases/py-psycopg2"
when "openbsd"
  version_major = 13
  user = "_postgresql"
  group = "_postgresql"
  db_dir = "/var/postgresql/data"
  package = "postgresql-server"
  extra_packages = %w[postgresql-contrib]
  conf_dir = db_dir
  psycopg2_package = "py3-psycopg2"
when "ubuntu"
  version_major = 12
  package = "postgresql-#{version_major}"
  conf_dir = "/etc/postgresql/#{version_major}/main"
  extra_packages = %w[postgresql-contrib]
  db_dir = "/var/lib/postgresql/#{version_major}/main"
  psycopg2_package = "python3-psycopg2"
when "devuan"
  version_major = os[:release].to_f >= 4 ? 13 : 11
  package = "postgresql-#{version_major}"
  conf_dir = "/etc/postgresql/#{version_major}/main"
  extra_packages = %w[postgresql-contrib]
  db_dir = "/var/lib/postgresql/#{version_major}/main"
  psycopg2_package = "python3-psycopg2"
when "redhat"
  version_major = 13
  package = "postgresql#{version_major}-server"
  db_dir = "/var/lib/pgsql/#{version_major}/data"
  conf_dir = db_dir
  extra_packages = ["postgresql#{version_major}-contrib"]
  service = "postgresql-#{version_major}"
  psycopg2_package = "python2-psycopg2"
  python_bin = "python"
when "fedora"
  version_major = 13
  package = "postgresql-server"
  db_dir = "/var/lib/pgsql/data"
  conf_dir = db_dir
  extra_packages = ["postgresql-contrib"]
  service = "postgresql"
  psycopg2_package = "python3-psycopg2"
  python_bin = "python"
end

config = "#{conf_dir}/postgresql.conf"
hba_config = "#{conf_dir}/pg_hba.conf"

describe package(package) do
  it { should be_installed }
end

extra_packages.each do |p|
  describe package p do
    it { should be_installed }
  end
end

describe package psycopg2_package do
  it { should be_installed }
end

describe file(config) do
  it { should be_file }
  it { should be_mode 600 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match(/Managed by ansible/) }
  its(:content) { should match Regexp.escape("default_text_search_config = 'pg_catalog.english'") }
  case os[:family]
  when "ubuntu", "devuan"
    its(:content) { should match Regexp.escape("data_directory = '#{db_dir}'") }
  end
end

describe file(hba_config) do
  it { should be_file }
  it { should be_mode 600 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match(/Managed by ansible/) }
  case os[:family]
  when "ubuntu", "devuan"
    its(:content) { should match(%r{host\s+all\s+all\s+127.0.0.1/32\s+md5$}) }
  else
    its(:content) { should match(%r{host\s+all\s+all\s+127.0.0.1/32\s+scram-sha-256$}) }
  end
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/postgresql") do
    it { should be_file }
    its(:content) { should match(/Managed by ansible/) }
    its(:content) { should match(/postgresql_flags="-w -s -m fast"/) }
  end
when "ubuntu", "devuan"
  describe file("#{conf_dir}/environment") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by user }
    it { should be_grouped_into group }
    its(:content) { should match(/Managed by ansible/) }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

describe command "psql --version" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should match(/^psql.* #{version_major}\.\d+/) }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

pgsql_users.each do |u|
  describe command "env PGPASSWORD=#{u[:password]} psql -h 127.0.0.1 -p 5432 -U #{u[:name]} -c '\\l' template1" do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }
    its(:stdout) { should match(/^\s+template1\s+/) }
  end
end

describe command "env PGPASSWORD=AdminPassWord psql -h 127.0.0.1 -p 5432 -U root -c '\\l' template1" do
  its(:stderr) { should eq "" }
  its(:stdout) { should match(/bar\s+\|\s+foo\s+\|\s+UTF8\s+\|/) }
  its(:exit_status) { should eq 0 }
end

describe command "#{python_bin} -c 'import psycopg2'" do
  its(:stderr) { should eq "" }
  its(:stdout) { should eq "" }
  its(:exit_status) { should eq 0 }
end
