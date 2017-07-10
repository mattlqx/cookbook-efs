require 'spec_helper'

describe 'efs::default' do
  shared_examples_for 'mounts efs filesystem' do
    it 'for /mnt/test' do
      expect(chef_run).to mount_mount_efs('/mnt/test').with(fsid: 'fs-1234abcd')
    end
  end

  shared_examples_for 'manages existing efs mounts' do
    it 'but not when disabled by default' do
      chef_run.converge(described_recipe)
      expect(chef_run).not_to run_ruby_block('remove unspecified efs mounts')
    end

    it 'by removing unspecified mounts' do
      chef_run.node.normal['efs']['remove_unspecified_mounts'] = true
      chef_run.converge(described_recipe)

      expect(chef_run).to run_ruby_block('remove unspecified efs mounts')
    end
  end

  context 'on Ubuntu' do
    let(:chef_run) do
      c = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '16.04')
      c.node.normal['efs']['mounts']['/mnt/test']['fsid'] = 'fs-1234abcd'
      c.node.automatic['ec2']['placement_availability_zone'] = 'us-west-2a'
      c.converge(described_recipe)
    end

    it 'installs nfs' do
      expect(chef_run).to install_package('nfs-common')
    end

    it_behaves_like 'mounts efs filesystem'
    it_behaves_like 'manages existing efs mounts'
  end

  context 'on RedHat' do
    let(:chef_run) do
      c = ChefSpec::SoloRunner.new(platform: 'redhat', version: '7.3')
      c.node.normal['efs']['mounts']['/mnt/test']['fsid'] = 'fs-1234abcd'
      c.node.automatic['ec2']['placement_availability_zone'] = 'us-west-2a'
      c.converge(described_recipe)
    end

    it 'installs nfs' do
      expect(chef_run).to install_package('nfs-utils')
    end

    it_behaves_like 'mounts efs filesystem'
    it_behaves_like 'manages existing efs mounts'
  end

  context 'uses mount_efs resource' do
    let(:fstab) do
      [
        'fs-fedc4321.efs.us-west-2.amazonaws.com:/ /mnt/test nfs4 ' \
        'nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,foo=bar,retrans=2 0 2',
        'some other test data'
      ]
    end

    let(:chef_run) do
      allow(IO).to receive(:readlines).and_call_original
      allow(IO).to receive(:readlines).with('/etc/fstab').and_return(fstab)
      allow(IO).to receive(:readlines).with('/etc/mtab').and_return(fstab)

      c = ChefSpec::SoloRunner.new(step_into: ['mount_efs']) do |node|
        node.normal['efs']['mounts']['/mnt/test']['fsid'] = 'fs-1234abcd'
        node.automatic['ec2']['placement_availability_zone'] = 'us-west-2a'
      end
      c.converge(described_recipe)
    end

    it 'creates mount directory' do
      expect(chef_run).to create_directory('/mnt/test')
    end

    it 'unmounts existing efs mount' do
      old_device = 'fs-fedc4321.efs.us-west-2.amazonaws.com:/'
      expect(chef_run).to disable_mount("/mnt/test #{old_device} unmount").with(device: old_device)
      expect(chef_run).to umount_mount("/mnt/test #{old_device} unmount").with(device: old_device)
    end

    it 'mounts efs mount' do
      expect(chef_run).to enable_mount('/mnt/test').with(device: 'fs-1234abcd.efs.us-west-2.amazonaws.com:/')
      expect(chef_run).to mount_mount('/mnt/test').with(device: 'fs-1234abcd.efs.us-west-2.amazonaws.com:/')
    end
  end
end
