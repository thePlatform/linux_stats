require 'pl_procstat'

# inspect.rb
#
# This module contains relatively expensive methods that will be
# called a single time  during monitor initialization.

module Procstat::OS::Inspect

  module DataFile
    CPUINFO = '/proc/cpuinfo'
    DISK_STATS = '/proc/diskstats'

    # FIXME: this should be set on a per-device basis with a map of
    #        device name to sector os_data size
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


  def self.cpuinfo
    ret = 0
    IO.readlines(DataFile::CPUINFO).each do |line|
      ret += 1 if line =~ /^processor/
    end
    ret
  end

  def self.disks
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


  def self.sector_size
    begin
      return File.read(DataFile::SECTOR_SIZE).strip().to_i
    rescue
      # handle CentOS 5
      return 512
    end
  end
end