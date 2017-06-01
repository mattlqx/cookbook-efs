def remove_unspecified_mounts(mounts, run_context)
  IO.readlines('/etc/fstab').each do |line|
    device, mount, _fstype, _options, _freq, _pass = line.split(/\s+/)
    next unless device && device.match(/fs-[a-f0-9]{8}\.efs\.[a-z]{2}-[a-z]+-\d\.amazonaws\.com/) \
        && !mounts.key?(mount)

    m = Chef::Resource::Mount.new(mount, run_context)
    m.device = device
    m.action = :nothing
    m.run_action(:disable)
    m.run_action(:umount)
  end
end
