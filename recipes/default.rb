#
# Cookbook Name:: efs
# Recipe:: default
#
# Copyright 2017, Matt Kulka
#

package node['efs']['nfs-package']

node['efs']['mounts'].each do |mount_point, attribs|
  mount_efs mount_point do
    fsid attribs['fsid']
    options attribs['options']
    action :mount
  end
end

ruby_block 'remove unspecified efs mounts' do
  only_if { node['efs']['remove_unspecified_mounts'] }
  block do
    EFS::Mount.remove_unspecified_mounts(node['efs']['mounts'], run_context)
  end
end
