require 'serverspec'

set :backend, :exec

case os[:family]
when 'redhat'
  package = 'nfs-utils'
when 'ubuntu', 'debian'
  package = 'nfs-common'
end

describe package(package) do
  it { should be_installed }
end

describe file('/mnt/test') do
  it { should be_mounted.with( :type => 'nfs4' ) }
  it { should be_directory }
end

describe file('/etc/fstab') do
  its(:content) { should match /amazonaws\.com:\/ \/mnt\/test nfs4/ }
end
