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

case os[:family]
when "freebsd"
  version_major = 12
  db_dir = "/var/db/postgres/data#{version_major}"
  package = "databases/postgresql12-server"
  extra_packages = %w[databases/postgresql12-contrib]
  conf_dir = db_dir
when "openbsd"
  version_major = 11
  user = "_postgresql"
  group = "_postgresql"
  db_dir = "/var/postgresql/data"
  package = "postgresql-server"
  extra_packages = %w[postgresql-contrib]
  conf_dir = db_dir
when "ubuntu"
  version_major = 10
  package = "postgresql-#{version_major}"
  conf_dir = "/etc/postgresql/#{version_major}/main"
  extra_packages = %w[postgresql-contrib]
  db_dir = "/var/lib/postgresql/#{version_major}/main"
when "redhat"
  version_major = 12
  package = "postgresql#{version_major}-server"
  db_dir = "/var/lib/pgsql/#{version_major}/data"
  conf_dir = db_dir
  extra_packages = ["postgresql#{version_major}-contrib"]
  service = "postgresql-#{version_major}"
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

describe file(config) do
  it { should be_file }
  it { should be_mode 600 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match(/Managed by ansible/) }
  its(:content) { should match Regexp.escape("default_text_search_config = 'pg_catalog.english'") }
  case os[:family]
  when "ubuntu"
    its(:content) { should match Regexp.escape("data_directory = '#{db_dir}'") }
  end
end

describe file(hba_config) do
  it { should be_file }
  it { should be_mode 600 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match(/Managed by ansible/) }
  its(:content) { should match(/local\s+all\s+all\s+trust$/) }
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/postgresql") do
    it { should be_file }
    its(:content) { should match(/Managed by ansible/) }
    its(:content) { should match(/postgresql_flags="-w -s -m fast"/) }
  end
when "ubuntu"
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
