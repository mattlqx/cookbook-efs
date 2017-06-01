require 'spec_helper'

describe 'efs::default' do
  shared_examples_for 'creates mount point' do
    it 'for /mnt/test' do
      expect(chef_run).to create_directory('/mnt/test')
    end
  end

  shared_examples_for 'mounts filesystem' do
    it 'for /mnt/test' do
      device = 'fs-1234abcd.efs.us-west-2.amazonaws.com:/'
      expect(chef_run).to enable_mount('/mnt/test').with(device: device)
      expect(chef_run).to mount_mount('/mnt/test').with(device: device)
    end
  end

  shared_examples_for 'manages existing efs mounts' do
    let(:fstab) do
      [
        'fs-fedc4321.efs.us-west-2.amazonaws.com:/ /mnt/foo nfs4 ' \
        "nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 2\n",
      ]
    end

    it 'but not when disabled by default' do
      chef_run.converge(described_recipe)
      expect(chef_run).to_not run_ruby_block('remove unspecified efs mounts')
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

    it_behaves_like 'creates mount point'
    it_behaves_like 'mounts filesystem'
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

    it_behaves_like 'creates mount point'
    it_behaves_like 'mounts filesystem'
    it_behaves_like 'manages existing efs mounts'
  end

  context 'when not on EC2' do
    let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'redhat', version: '7.3') }

    before do
      chef_run.node.normal['efs']['mounts']['/mnt/test']['fsid'] = 'fs-1234abcd'
    end

    it 'should not converge without region' do
      expect do
        chef_run.converge(described_recipe)
      end.to raise_error(RuntimeError)
    end

    it 'should converge with region' do
      chef_run.node.normal['efs']['mounts']['/mnt/test']['region'] = 'us-west-2'
      chef_run.converge(described_recipe)
    end
  end
end
