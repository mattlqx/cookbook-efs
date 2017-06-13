#
# Cookbook Name:: efs
# Recipe:: default
#
# Copyright 2017, Matt Kulka
#

case node['platform']
when 'ubuntu', 'debian'
  package 'nfs-common'
when 'redhat'
  package 'nfs-utils'
end

node['efs']['mounts'].each do |mount_point, attribs|
  attribs = attribs.to_hash
  attribs['rsize'] ||= node['efs']['rsize']
  attribs['wsize'] ||= node['efs']['wsize']
  attribs['behavior'] ||= node['efs']['behavior']
  attribs['timeout'] ||= node['efs']['timeout']
  attribs['retrans'] ||= node['efs']['retrans']
  attribs['options'] ||= "nfsvers=4.1,rsize=#{attribs['rsize']},wsize=#{attribs['wsize']}," \
    "#{attribs['behavior']},timeo=#{attribs['timeout']},retrans=#{attribs['retrans']}"

  begin
    region = attribs.fetch('region', nil) || node['ec2']['placement_availability_zone'][0..-2]
  rescue NoMethodError
    raise "No region specified for mount #{mount_point} and this doesn\'t appear to be an EC2 instance."
  end

  raise "Mount #{mount_point} has an invalid fsid." unless attribs['fsid'] =~ /fs-[a-f0-9]{8}/

  directory mount_point

  mount mount_point do
    fstype 'nfs4'
    device attribs['fsid'] + '.efs.' + region + '.amazonaws.com:/'
    options attribs['options']
    action %i[enable mount]
  end
end

ruby_block 'remove unspecified efs mounts' do
  only_if { node['efs']['remove_unspecified_mounts'] }
  block do
    remove_unspecified_mounts(node['efs']['mounts'], run_context)
  end
end
