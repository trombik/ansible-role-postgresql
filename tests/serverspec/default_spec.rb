require "spec_helper"
require "serverspec"

package = "postgresql-server"
service = "postgresql"
user    = "postgres"
group   = "postgres"
ports   = [5432]
db_dir  = "/var/lib/postgresql/data"
extra_packages = []

case os[:family]
when "freebsd"
  db_dir = "/var/db/postgres/data12"
  package = "databases/postgresql12-server"
  extra_packages = %w[databases/postgresql12-contrib]
when "openbsd"
  user = "_postgresql"
  group = "_postgresql"
  db_dir = "/var/postgresql/data"
  package = "postgresql-server"
  extra_packages = %w[postgresql-contrib]
end

config = "#{db_dir}/postgresql.conf"
hba_config = "#{db_dir}/pg_hba.conf"

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
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
