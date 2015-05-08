require 'pl_procstat'

# Discovers the mounted partitions on the filesystem and
# reports on space used.
module Procstat::OS::Mounts

  IGNORE_PARTITIONS = [
      'docker',
      '^\/proc',
      '^\/run',
      '^\/sys',
      '^\/cgroup'
  ]

  module DataFile
    MOUNTS = '/proc/mounts'
  end

  def self.report
    # execution time: 0.3 ms  [LOW]
    storage_report = {}
    @@mounted_partitions.each do |partition|
      usage = partition_used(partition)
      storage_report[partition] = {}
      storage_report[partition][:total_kb] = usage[0]
      storage_report[partition][:available_kb] = usage[1]
      unless usage[0] == 0
        storage_report[partition][:used_pct] = 100.0 * (1-usage[1].to_f / usage[0].to_f)
      end
    end
    storage_report
  end

# see https://www.ruby-forum.com/topic/4416522
# returns: array of partition use: [
#   <used kilobytes>
#   <max kilobytes>
# ]
  def self.partition_used(partition)
    b=' '*128
    syscall(137, partition, b)
    a=b.unpack('QQQQQ')
    [a[2]*@@blocks_per_kilobyte, a[4]*@@blocks_per_kilobyte]
  end

  def self.mounts
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

  # do the expensive stuff up front
  def self.init
    @@blocks_per_kilobyte = 4 # TODO: calculate from info in /proc?  Where?
    @@mounted_partitions = mounts
  end

end

Procstat::OS::Mounts.init

