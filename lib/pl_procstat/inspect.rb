require 'pl_procstat'

# inspect.rb
#
# Methods here will typically be called a single time during monitor
# initialization rather than on an ongoing basis during report
# generation.  There is less emphasis on getting these to perform
# as fast as possible, given their one-time use.
module Procstat
  module Inspect
    module DataFile
      CPUINFO = '/proc/cpuinfo'
      DISK_STATS = '/proc/diskstats'
      MOUNTS = '/proc/mounts'
      # FIXME: this should be set on a per-device basis with a map of
      #        device name to sector data size
      SECTOR_SIZE = '/sys/block/sda/queue/hw_sector_size'
    end

    IGNORE_DISKS = [
        '^dm-[0-9]',
        '^fd[0-9]',
        '^ram',
        '^loop',
        '^sr',
        '^sd.*[0-9]'
    ]
    IGNORE_PARTITIONS = [
        'docker',
        '^\/proc',
        '^\/run',
        '^\/sys'
    ]

    def Inspect.cpuinfo
      ret = 0
      IO.readlines(DataFile::CPUINFO).each do |line|
        ret += 1 if line =~ /^processor/
      end
      ret
    end

    def Inspect.disks
      disk_list = []
      IO.readlines(DataFile::DISK_STATS).each do |line|
        words = line.split
        disk_list.push words[2]
      end
      IGNORE_DISKS.each do |pattern|
        disk_list.reject! { |x| x =~ /#{pattern}/ }
      end
      disk_list
    end

    def Inspect.mounts
      mount_list = []
      IO.readlines(DataFile::MOUNTS).each do |line|
        mount = line.split[1]
        next if IGNORE_PARTITIONS.include? mount
        mount_list.push line.split[1].strip
      end
      IGNORE_PARTITIONS.each do |partition|
        mount_list.reject! { |x| x =~ /#{partition}/ }
      end
      mount_list
    end

    def Inspect.sector_size
      begin
        return File.read(DataFile::SECTOR_SIZE).strip().to_i
      rescue
        # handle CentOS 5
        return 512
      end
    end
  end
end