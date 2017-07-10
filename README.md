# efs Cookbook

Cookbook to mount Elastic Filesystem endpoints in Amazon Web Services.

You just configure global defaults (presently the recommended values from Amazon) and individual mounts through node attributes. You also have the option of using the `mount_efs` resource within your own recipes.

## Requirements

- NFS

### Platforms

- Ubuntu 16.04
- Centos 7.2
- RHEL 7.2
- Debian (untested)

## Attributes

### efs::default

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['efs']['mounts']</tt></td>
    <td>hash of hashes</td>
    <td>Keys are mount point paths, values can be any of the keys below. The <tt>fsid</tt> key is required. Any other optional keys will use global defaults from the attributes below.</td>
    <td><tt>{}</tt></td>
  </tr>
  <tr>
    <td><tt>['efs']['mounts'][mount point]['fsid']</tt></td>
    <td>string (required)</td>
    <td>FSID of the Elastic Filesystem (e.g. fs-1234abcd)</td>
    <td></td>
  </tr>
  <tr>
    <td><tt>['efs']['mounts'][mount point]['region']</tt></td>
    <td>string</td>
    <td>Override AWS region for the mount</td>
    <td>derived from node['ec2']['placement_availability_zone']</td>
  </tr>
  <tr>
    <td><tt>['efs']['mounts'][mount point]['options']</tt></td>
    <td>string</td>
    <td>Override mount options string</td>
    <td>generated from attributes of mount and global below</td>
  </tr>
  <tr>
    <td><tt>['efs']['rsize']</tt></td>
    <td>int</td>
    <td>maximum read size in bytes</td>
    <td><tt>1048576</tt></td>
  </tr>
  <tr>
    <td><tt>['efs']['wsize']</tt></td>
    <td>int</td>
    <td>maximum write size in bytes</td>
    <td><tt>1048576</tt></td>
  </tr>
  <tr>
    <td><tt>['efs']['timeout']</tt></td>
    <td>int</td>
    <td>timeout between retries in deciseconds</td>
    <td><tt>600</tt></td>
  </tr>
  <tr>
    <td><tt>['efs']['retrans']</tt></td>
    <td>int</td>
    <td>number of retries before further action</td>
    <td><tt>2</tt></td>
  </tr>
  <tr>
    <td><tt>['efs']['behavior']</tt></td>
    <td>string</td>
    <td>determines timeout behavior (hard or soft)</td>
    <td><tt>hard</tt></td>
  </tr>
  <tr>
    <td><tt>['efs']['remove_unspecified_mounts']</tt></td>
    <td>boolean</td>
    <td>Unmount and remove any EFS mount in fstab that is not specified by <tt>['efs']['mounts']</tt></td>
    <td><tt>false</tt></td>
  </tr>
</table>

## Usage

### efs::default

Configure any desired mounts under `node['efs']['mounts']` and include `efs` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[efs]"
  ]
}
```

### mount_efs

This cookbook is implemented with a custom resource so you can use `mount_efs` in your cookbook recipes as well with the same available attributes as the `node['efs']['mounts']` structure.

## Contributing

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

## License and Authors

Authors: Matt Kulka <matt@lqx.net>
