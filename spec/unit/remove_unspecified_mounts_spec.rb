require 'spec_helper'
require './libraries/remove_unspecified_mounts'

describe 'remove_unspecified_mounts' do
  let(:fstab) do
    [
      'fs-fedc4321.efs.us-west-2.amazonaws.com:/ /mnt/foo nfs4 ' \
      "nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 2\n",
      'fs-1234abcd.efs.us-west-2.amazonaws.com:/ /mnt/test nfs4 ' \
      "nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 2\n",
      "/dev/sda1 / ext4 defaults 0 0\n"
    ]
  end

  let(:chef_run) do
    c = ChefSpec::SoloRunner.new(platform: 'redhat', version: '7.3')
    c.node.normal['efs']['mounts']['/mnt/test']['fsid'] = 'fs-1234abcd'
    c.node.normal['efs']['remove_unspecified_mounts'] = true
    c.node.automatic['ec2']['placement_availability_zone'] = 'us-west-2a'
    c
  end

  before do
    allow(IO).to receive(:readlines).and_call_original
    allow(IO).to receive(:readlines).with('/etc/fstab').and_return(fstab)
  end

  it 'removes unspecified efs mounts' do
    m = Chef::Resource::Mount.new('/mnt/foo', chef_run.run_context)
    allow(Chef::Resource::Mount).to receive(:new).and_return(m)
    allow(m).to receive(:run_action).and_return(true)
    allow(m).to receive(:device).with('fs-fedc4321.efs.us-west-2.amazonaws.com:/').and_call_original
    allow(m).to receive(:action).with(:nothing).and_call_original

    remove_unspecified_mounts(chef_run.node['efs']['mounts'], chef_run.run_context)
    expect(Chef::Resource::Mount).to have_received(:new).once
    expect(m).to have_received(:run_action).with(:disable)
    expect(m).to have_received(:run_action).with(:umount)
  end
end
