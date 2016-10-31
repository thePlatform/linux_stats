# The MIT License (MIT)
#
# Copyright (c) 2015-16 Comcast Technology Solutions
#
#     Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'linux_stats'

# Discovers the mounted partitions on the filesystem and
# reports on space used.
module LinuxStats::OS::Mounts
  IGNORE_PARTITIONS = [
      'docker',
      '^\/proc',
      '^\/run',
      '^\/sys',
      '^\/cgroup',
      '\['
  ]
  PROC_DIRECTORY_DEFAULT = '/proc'
  CONTAINER_MOUNT_PREFIX = '/hostfs'

  module DataFile
    MOUNTS_PATH = '/mounts'
  end

  class Reporter

    attr_accessor :blocks_per_kilobyte,
                  :mounted_partitions

    def initialize(data_directory = PROC_DIRECTORY_DEFAULT)
      set_data_paths data_directory
      @blocks_per_kilobyte = 4 # TODO: calculate from info in /proc?  Where?
      @mounted_partitions = mounts
    end

    def set_data_paths(data_directory = nil)
      @proc_data_source = "#{data_directory}#{DataFile::MOUNTS_PATH}"
    end

    def report
      # execution time: 0.3 ms  [LOW]
      storage_report = {}
      mounted_partitions.each do |partition|
        usage = partition_used(partition)

        # When reporting, we want the mounts to appear as if they are from the host, not the
        # container in which linux_stats is running.  The '//' case is a bit sloppy, but it's to
        # handle '/' properly.
        if @proc_data_source.include? 'hostproc'
          partition.sub! '/hostfs','/'
          partition.sub! '//','/'
        end

        storage_report[partition] = {}
        storage_report[partition][:total_kb] = usage[0]
        storage_report[partition][:available_kb] = usage[1]
        unless usage[0] == 0
          storage_report[partition][:used_pct] = 100.0 * (1 - usage[1].to_f / usage[0].to_f)
        end
      end
      storage_report
    end

    # see https://www.ruby-forum.com/topic/4416522
    # returns: array of partition use: [
    #   <used kilobytes>
    #   <max kilobytes>
    # ]
    def partition_used(partition)
      b = ' ' * 128
      syscall(137, partition, b)
      a = b.unpack('QQQQQ')
      [a[2] * blocks_per_kilobyte, a[4] * blocks_per_kilobyte]
    end

    def mounts
      mount_list = []
      IO.readlines(@proc_data_source).each do |line|
        mount = line.split[1]

        # Inside a container, we should exclude everything not in the well-known host filesystem
        # mount.
        if @proc_data_source.include? 'hostproc'
          next unless mount.include? CONTAINER_MOUNT_PREFIX
        end

        next if IGNORE_PARTITIONS.include? mount
        mount_list.push line.split[1].strip
      end
      IGNORE_PARTITIONS.each do |partition|
        mount_list.reject! { |x| x =~ /#{partition}/ }
      end
      mount_list
    end

  end
end
