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
      '\/dev\/pts',
      '^\/proc',
      '^\/run',
      '^\/sys',
      '^\/cgroup',
      '^\/hostfs\/proc',
      '^\/hostfs\/run',
      '^\/hostfs\/sys',
      '^\/hostfs\/cgroup',
      '\['
  ]
  PROC_DIRECTORY_DEFAULT = '/proc'
  PROC_DIRECTORY_CONTAINER = '/hostproc'
  CONTAINER_MOUNT_PREFIX = 'hostfs'

  module DataFile
    MOUNTS_PATH = '/mounts'
  end

  class Reporter

    attr_accessor :blocks_per_kilobyte,
                  :mounted_partitions,
                  :container_prefix

    def initialize(data_directory = PROC_DIRECTORY_DEFAULT, container_mount_name =
        CONTAINER_MOUNT_PREFIX, data = nil, test_mode = false)
      set_data_paths data_directory
      set_container_mount container_mount_name
      @blocks_per_kilobyte = 4 # TODO: calculate from info in /proc?  Where?
      @test_mode = test_mode
      if data && @test_mode
        @mounted_partitions = mounts(data)
      else
        @mounted_partitions = mounts
      end
    end

    def set_data_paths(data_directory = nil)
      @proc_data_source = "#{data_directory}#{DataFile::MOUNTS_PATH}"
    end

    def set_container_mount(container_mount_name = nil)
      @container_prefix = container_mount_name
    end

    def report
      # execution time: 0.3 ms  [LOW]
      storage_report = {}

      mounted_partitions.each do |partition|
        # Because of the way this runs on successive iterations (via the binary or within a Ruby
        # process using this as a library), we need to manually re-build the host path when
        # operating against data using when he are operating in the defined container mode.
        if (@proc_data_source.include? PROC_DIRECTORY_CONTAINER) && (!partition.include? @container_prefix)
          add_container_directory partition
        end

        usage = partition_used(partition)
        # When reporting, we want the mounts to appear as if they are from the host, not the
        # container in which linux_stats is running.  The '//' case is a bit sloppy, but it's to
        # handle '/' properly.
        if @proc_data_source.include? PROC_DIRECTORY_CONTAINER
          strip_container_directory partition
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

    def strip_container_directory(mount_path = nil)
      mount_path.sub! "/#{@container_prefix}",'/'
      mount_path.sub! '//','/'
    end

    def add_container_directory(mount_path = nil)
      mount_path.sub! /^\//,"/#{@container_prefix}/"
      mount_path.sub! '//','/'
    end

    # see https://www.ruby-forum.com/topic/4416522
    # returns: array of partition use: [
    #   <used kilobytes>
    #   <max kilobytes>
    # ]
    def partition_used(partition)
      # Return magic number if in test_mode to prevent syscall
      return '128' if @test_mode
      b = ' ' * 128
      syscall(137, partition, b)
      a = b.unpack('QQQQQ')
      [a[2] * blocks_per_kilobyte, a[4] * blocks_per_kilobyte]
    end

    def mounts(data = nil)
      mount_list = []
      unless data
        IO.readlines(@proc_data_source).each do |line|
          mount = line.split[1]

          # Inside a container, we should exclude everything not in the well-known host filesystem
          # mount.
          if @proc_data_source.include? PROC_DIRECTORY_CONTAINER
            next unless mount.include? @container_prefix
          end

          next if IGNORE_PARTITIONS.include? mount
          mount_list.push line.split[1].strip
        end
      else
        mount_test_data = StringIO.new(data)
        mount_test_data.readlines.each do |line|
          mount = line.split[1]

          # Inside a container, we should exclude everything not in the well-known host filesystem
          # mount.
          if @proc_data_source.include? PROC_DIRECTORY_CONTAINER
            next unless mount.include? @container_prefix
          end

          next if IGNORE_PARTITIONS.include? mount
          mount_list.push line.split[1].strip
        end
      end
        IGNORE_PARTITIONS.each do |partition|
          mount_list.reject! { |x| x =~ /#{partition}/ }
        end
        mount_list
    end

    # Test hook used for mount list parsing tests
    def verify_mount_count
      @mounted_partitions.length
    end

  end
end
