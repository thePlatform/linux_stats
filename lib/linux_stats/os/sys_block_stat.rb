
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

module LinuxStats::OS::BlockIO
  module Column
    READS = 0
    READ_SECTORS = 2
    READ_TIME_MS = 3
    WRITES = 4
    WRITE_SECTORS = 6
    WRITE_TIME_MS = 7
    IN_PROGRESS = 8
    ACTIVE_TIME_MS = 9
    QUEUE_TIME_MS = 10
  end

  module DataFile
    CPUINFO = '/proc/cpuinfo'
    DISK_STATS = '/proc/diskstats'
    SECTOR_SIZE = '/sys/block/sda/queue/hw_sector_size'
  end

  def self.cpuinfo
    ret = 0
    IO.readlines(DataFile::CPUINFO).each do |line|
      ret += 1 if line =~ /^processor/
    end
    ret
  end

  def self.sector_size
    begin
      return File.read(DataFile::SECTOR_SIZE).strip.to_i
    rescue
      # handle CentOS 5
      return 512
    end
  end

  def self.watched_disks(data = nil)
    disk_list = []
    data = File.read(DataFile::DISK_STATS) unless data
    data.each_line do |line|
      words = line.split
      disk_name = words[2]
      disk_list.push disk_name if File.exists? "/sys/block/#{disk_name}/stat"
    end
    IGNORE_DISKS.each do |pattern|
      disk_list.reject! { |x| x =~ /#{pattern}/ }
    end
    disk_list
  end

  BYTES_PER_SECTOR = sector_size
  IGNORE_DISKS = [
    '^dm-[0-9]',
    '^fd[0-9]',
    '^ram',
    '^loop',
    '^sr',
    '^sd.*[0-9]'
  ]
  NUM_CPU = cpuinfo
  WATCHED_DISKS = watched_disks

  class Reporter
    def initialize(_data = nil)
      set_stats
    end

    def report(elapsed_time = nil)
      prev_stats = @current_stats
      prev_timestamp = @current_timestamp
      set_stats
      elapsed_time = @current_timestamp - prev_timestamp unless elapsed_time
      ret = {}
      WATCHED_DISKS.each do |disk_name|
        cur_disk = @current_stats[disk_name]
        prev_disk = prev_stats[disk_name]
        ret[disk_name] = {}
        ret[disk_name][:reads_persec] = (cur_disk.reads - prev_disk.reads) / elapsed_time
        ret[disk_name][:writes_persec] = (cur_disk.writes - prev_disk.writes) / elapsed_time
        ret[disk_name][:bytes_read_persec] =
            (cur_disk.read_bytes - prev_disk.read_bytes) / elapsed_time
        ret[disk_name][:bytes_written_persec] =
            (cur_disk.write_bytes - prev_disk.write_bytes) / elapsed_time
        # mimic iostat avgqu-sz: (delta (total queue time ms))/(elapsed ms)
        ret[disk_name][:avg_queue_size] = (cur_disk.queue_time_ms - prev_disk.queue_time_ms) / (elapsed_time * 1000)
        # mimic iostat avgrq-sz, using bytes instead of sectors: bytes/requests
        if ( cur_disk.reads - prev_disk.reads + cur_disk.writes - prev_disk.writes > 0)
            ret[disk_name][:avg_request_bytes] =
                (cur_disk.read_bytes - prev_disk.write_bytes + cur_disk.write_bytes - prev_disk.read_bytes) /
                (cur_disk.reads - prev_disk.reads + cur_disk.writes - prev_disk.writes)
        else
            ret[disk_name][:avg_request_bytes] = 0
        end

        cpu_ms = elapsed_time * NUM_CPU * 1.25

	# TODO: pct_active does not always agree w/ iostat's util column
	# see http://stackoverflow.com/questions/4458183/how-the-util-of-iostat-is-computed
        pct_active = (cur_disk.active_time_ms - prev_disk.active_time_ms) / cpu_ms
        # pct_active is an approximation, which may occasionally be a bit over 100%.  We
        # cap it here at 100 to avoid confusing users.
        pct_active = 100 if pct_active > 100
        ret[disk_name][:percent_active] = pct_active
      end
      ret
    end

    def set_stats
      @current_timestamp = Time.now
      @current_stats = {}
      WATCHED_DISKS.each do |disk_name|
        data = File.read("/sys/block/#{disk_name}/stat")
        stats = ThroughputData.new(data, BYTES_PER_SECTOR)
        @current_stats[disk_name] = stats
      end
    end
  end

  class ThroughputData
    #
    # /sys/block/<dev>/stat
    #
    # Num   Name            units         description
    # ---   ----            -----         -----------
    #  0    read I/Os       requests      number of read I/Os processed
    #  1    read merges     requests      number of read I/Os merged with in-queue I/O
    #  2    read sectors    sectors       number of sectors read
    #  3    read ticks      milliseconds  total wait time for read requests
    #  4    write I/Os      requests      number of write I/Os processed
    #  5    write merges    requests      number of write I/Os merged with in-queue I/O
    #  6    write sectors   sectors       number of sectors written
    #  7    write ticks     milliseconds  total wait time for write requests
    #  8    in_flight       requests      number of I/Os currently in flight
    #  9    io_ticks        milliseconds  total time this block device has been active
    #  10   time_in_queue   milliseconds  total wait time for all requests
    #
    # See https://www.kernel.org/doc/Documentation/block/stat.txt for more info
    #
    attr_reader :reads,
                :read_bytes,
                :read_time_ms,
                :writes,
                :write_bytes,
                :write_time_ms,
                :in_progress,
                :active_time_ms,
                :queue_time_ms

    def initialize(data, bytes_per_sector)
      words = data.split
      @reads = words[Column::READS].to_i
      @read_bytes = words[Column::READ_SECTORS].to_i * bytes_per_sector
      @read_time_ms = words[Column::READ_TIME_MS].to_i
      @writes = words[Column::WRITES].to_i
      @write_bytes = words[Column::WRITE_SECTORS].to_i * bytes_per_sector
      @write_time_ms = words[Column::WRITE_TIME_MS].to_i
      @in_progress = words[Column::IN_PROGRESS].to_i
      @active_time_ms = words[Column::ACTIVE_TIME_MS].to_i
      @queue_time_ms = words[Column::QUEUE_TIME_MS].to_i
    end
  end

end
