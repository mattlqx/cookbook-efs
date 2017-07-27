name             'efs'
maintainer       'Matt Kulka'
maintainer_email 'matt@lqx.net'
license          'MIT'
description      'Installs/Configures Amazon Elastic Filesystem mounts'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.1'

source_url 'https://github.com/mattlqx/cookbook-efs' if respond_to?(:source_url)
issues_url 'https://github.com/mattlqx/cookbook-efs/issues' if respond_to?(:issues_url)

chef_version '>= 12' if respond_to?(:chef_version)

if respond_to?(:supports)
  supports 'ubuntu'
  supports 'centos'
  supports 'redhat'
  supports 'debian'
end
