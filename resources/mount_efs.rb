resource_name :mount_efs

default_action :mount

property :mount_point, String, name_property: true, desired_state: false
property :fsid, String, desired_state: false, regex: [/fs-[a-f0-9]{8}/]
property :region, String, desired_state: false
property :rsize, Integer, default: node['efs']['rsize'], desired_state: false
property :wsize, Integer, default: node['efs']['wsize'], desired_state: false
property :behavior, String, default: node['efs']['behavior'], desired_state: false
property :timeout, Integer, default: node['efs']['timeout'], desired_state: false
property :retrans, Integer, default: node['efs']['retrans'], desired_state: false
property :options, String, desired_state: false

load_current_value do |new_resource|
  @mount = EFS::Mount.new(new_resource.mount_point, new_resource.fsid, region_value)
  (@mount.load_existing_options if @mount.exists?) || current_value_does_not_exist!

  region region_value
  rsize @mount.rsize unless @mount.rsize.nil?
  wsize @mount.wsize unless @mount.wsize.nil?
  behavior @mount.behavior unless @mount.behavior.nil?
  timeout @mount.timeout unless @mount.timeout.nil?
  retrans @mount.retrans unless @mount.retrans.nil?
  options @mount.extra_options unless @mount.extra_options.nil?
end

def region_value
  begin
    region ||= node['ec2']['placement_availability_zone'][0..-2]
  rescue NoMethodError
    raise "No region specified for mount #{mount_point} and this doesn\'t appear to be an EC2 instance."
  end
  region
end

def new_object # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  mount = EFS::Mount.new(mount_point, fsid, region_value) if @mount.nil?
  mount.rsize = rsize unless rsize.nil?
  mount.wsize = wsize unless wsize.nil?
  mount.behavior = behavior unless behavior.nil?
  mount.timeout = timeout unless timeout.nil?
  mount.retrans = retrans unless retrans.nil?
  mount.extra_options = options unless options.nil?
  mount
end

action :mount do
  mount = new_object

  directory new_resource.mount_point

  converge_if_changed do
    mount new_resource.mount_point do
      fstype 'nfs4'
      device mount.device
      options mount.options
      action %i[enable mount]
    end
  end
end

action :umount do
  mount = new_object

  mount new_resource.mount_point do
    fstype 'nfs4'
    device mount.device
    options mount.options
    action %i[disable umount]
  end
end
