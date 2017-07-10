module EFS
  # Class representing an Elastic Filesystem share/mount
  class Mount
    attr_reader :mount
    attr_reader :fsid
    attr_reader :region
    attr_accessor :rsize
    attr_accessor :wsize
    attr_accessor :behavior
    attr_accessor :timeout
    attr_accessor :retrans
    attr_accessor :extra_options

    def initialize(mount, fsid, region)
      raise 'Non-nil region required' if region.nil?

      @mount = mount
      @fsid = fsid
      @region = region
      @extra_options = ''
    end

    def options_from_line(line) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      linedevice, linemount, _fstype, options, _freq, _pass = line.split(/\s+/)
      raise "Device does not match #{device}" if linedevice != device
      raise "Mount does not match #{mount}" if linemount != mount
      options.split(',').each do |pair|
        k, v = pair.split('=')
        case k
        when 'rsize'
          @rsize = v
        when 'wsize'
          @wsize = v
        when 'soft', 'hard'
          @behavior = k
        when 'timeo'
          @timeout = v
        when 'retrans'
          @retrans = v
        when 'nfsvers'
          next
        else
          @extra_options += ',' unless @extra_options.empty?
          @extra_options += k
          @extra_options += "=#{v}" if v
        end
      end
    end

    def load_existing_options
      options_from_line(existing_line) if existing_line
    end

    def standard_options
      "nfsvers=4.1,rsize=#{@rsize},wsize=#{@wsize},#{@behavior},timeo=#{@timeout},retrans=#{@retrans}"
    end

    def options
      @extra_options.empty? ? standard_options : standard_options + ',' + @extra_options
    end

    def device
      "#{@fsid}.efs.#{@region}.amazonaws.com:/"
    end

    def exists?
      !fstab_line.nil? || !mtab_line.nil?
    end

    def fstab_line
      file_include('/etc/fstab')
    end

    def mtab_line
      file_include('/etc/mtab')
    end

    def file_include(file)
      IO.readlines(file).each do |line|
        return line.chomp if /^\s*#{device}/ =~ line
      end
      nil
    end

    def existing_line
      mtab_line || fstab_line
    end

    def self.remove_unspecified_mounts(mounts, run_context)
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
  end
end
