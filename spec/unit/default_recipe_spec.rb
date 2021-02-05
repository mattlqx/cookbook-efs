require 'spec_helper'

describe 'efs::default' do
  platform 'ubuntu', '20.04'

  override_attributes['efs']['mounts']['/mnt/test']['fsid'] = 'fs-1234abcd'
  automatic_attributes['ec2']['placement_availability_zone'] = 'us-west-2a'

  shared_examples_for 'mounts efs filesystem' do
    it 'for /mnt/test' do
      expect(chef_run).to mount_mount_efs('/mnt/test').with(fsid: 'fs-1234abcd')
    end
  end

  shared_examples_for 'manages existing efs mounts' do
    it 'but not when disabled by default' do
      expect(chef_run).not_to run_ruby_block('remove unspecified efs mounts')
    end

    context 'when enabled' do
      override_attributes['efs']['remove_unspecified_mounts'] = true

      it 'by removing unspecified mounts' do
        expect(chef_run).to run_ruby_block('remove unspecified efs mounts')
      end
    end
  end

  context 'when on Ubuntu' do
    platform 'ubuntu', '20.04'

    it 'installs nfs' do
      expect(chef_run).to install_package('nfs-common')
    end

    it_behaves_like 'mounts efs filesystem'
    it_behaves_like 'manages existing efs mounts'
  end

  context 'when on RedHat' do
    platform 'redhat', '8'

    it 'installs nfs' do
      expect(chef_run).to install_package('nfs-utils')
    end

    it_behaves_like 'mounts efs filesystem'
    it_behaves_like 'manages existing efs mounts'
  end

  context 'with mount_efs resource' do
    let(:fstab) do
      [
        'fs-fedc4321.efs.us-west-2.amazonaws.com:/ /mnt/test nfs4 ' \
        'nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,foo=bar,retrans=2 0 2',
        'some other test data'
      ]
    end

    before do
      allow(IO).to receive(:readlines).and_call_original
      allow(IO).to receive(:readlines).with('/etc/fstab').and_return(fstab)
      allow(IO).to receive(:readlines).with('/etc/mtab').and_return(mtab)
    end

    step_into :mount_efs

    describe 'when already mounted' do
      let(:mtab) { fstab }

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

    describe 'when not mounted' do
      let(:mtab) { 'nothing here' }

      it 'creates mount directory' do
        expect(chef_run).to create_directory('/mnt/test')
      end

      it 'mounts efs mount' do
        expect(chef_run).to enable_mount('/mnt/test').with(device: 'fs-1234abcd.efs.us-west-2.amazonaws.com:/')
        expect(chef_run).to mount_mount('/mnt/test').with(device: 'fs-1234abcd.efs.us-west-2.amazonaws.com:/')
      end
    end
  end
end
