require 'spec_helper'
require './libraries/efs'

# rubocop:disable RSpec/InstanceVariable
describe 'efs class' do
  let(:valid_fsid) { 'fs-fedc4321' }
  let(:region) { 'us-west-2' }
  let(:mount_point) { '/mnt/test' }
  let(:fstab) do
    [
      'fs-fedc4321.efs.us-west-2.amazonaws.com:/ /mnt/test nfs4 ' \
      'nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,foo=bar,retrans=2 0 2',
      'some other test data'
    ]
  end
  let(:fstab_with_dupe) do
    fstab.clone.insert(1, 'fs-1234abcd.efs.us-west-2.amazonaws.com:/ /mnt/test nfs4 ' \
                    'nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,foo=bar,retrans=2 0 2')
  end

  before do
    allow(IO).to receive(:readlines).and_call_original
    @mount = EFS::Mount.new(mount_point, valid_fsid, region)
  end

  it 'takes basic arguments' do
    expect(@mount).not_to be_nil
  end

  it 'fails without a region' do
    expect do
      EFS::Mount.new(mount_point, valid_fsid, nil)
    end.to raise_error(RuntimeError)
  end

  context 'has existing fstab line' do
    before do
      allow(IO).to receive(:readlines).with('/etc/fstab').and_return(fstab)
      allow(IO).to receive(:readlines).with('/etc/mtab').and_return([])
    end

    it 'exists in correct file' do
      expect(@mount.exists?).to be true
      expect(@mount.fstab_lines).to eq([fstab[0]])
      expect(@mount.mtab_lines).to eq([])
    end
  end

  context 'has multiple existing fstab lines' do
    before do
      allow(IO).to receive(:readlines).with('/etc/fstab').and_return(fstab_with_dupe)
      allow(IO).to receive(:readlines).with('/etc/mtab').and_return(fstab)
    end

    it 'sees both entries' do
      expect(@mount.exists?).to be true
      expect(@mount.fstab_lines).to eq([fstab_with_dupe[0], fstab_with_dupe[1]])
    end

    it 'shows other mounts' do
      expect(@mount.other_mounts).to eq([fstab_with_dupe[1]])
    end
  end

  context 'has existing mtab line' do
    before do
      allow(IO).to receive(:readlines).with('/etc/mtab').and_return(fstab)
      allow(IO).to receive(:readlines).with('/etc/fstab').and_return([])
    end

    it 'exists in correct file' do
      expect(@mount.exists?).to be true
      expect(@mount.mtab_lines).to eq([fstab[0]])
      expect(@mount.fstab_lines).to eq([])
    end

    it 'finds existing line' do
      expect(@mount.existing_line).to eq(fstab[0])
    end

    it 'loads existing options' do
      @mount.load_existing_options

      expect(@mount.options).to eq('nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,foo=bar')
    end

    it 'finds extra options' do
      @mount.load_existing_options

      expect(@mount.extra_options).to eq('foo=bar')
    end

    it 'returns proper device' do
      expect(@mount.device).to eq('fs-fedc4321.efs.us-west-2.amazonaws.com:/')
    end
  end
end
