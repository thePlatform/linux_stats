class DiskIOStat

  # The /proc/diskstats file displays the I/O statistics
  # of block devices. Each line contains the following 14
  # fields:
  # 1 - major number
  # 2 - minor mumber
  # 3 - device name
  # 4 - reads completed successfully
  # 5 - reads merged
  # 6 - sectors read**
  # 7 - time spent reading (ms)
  # 8 - writes completed
  # 9 - writes merged
  # 10 - sectors written**
  # 11 - time spent writing (ms)
  # 12 - I/Os currently in progress
  # 13 - time spent doing I/Os (ms)
  # 14 - weighted time spent doing I/Os (ms)

  # **see /sys/block/sdb/queue/hw_sector_size to get bytes/sector. (Usually 512)

  attr_reader :name,
              :kb_read,
              :kb_written,
              :reads,
              :writes,
              :time_io,
              :time_reading,
              :time_writing,
              :in_progress

  def initialize(words, disk_sector_size)
    @name = words[2]
    @reads = words[3].to_i
    @writes = words[7].to_i
    @time_io = words[12].to_i
    @time_reading = words[6].to_i
    @time_writing = words[10].to_i
    @in_progress = words[11].to_i
    @kb_written = words[9].to_i * disk_sector_size
    @kb_read = words[6].to_i * disk_sector_size
  end

  def to_s
    "name: #{name}\n" +
        "reads: #{reads}\n" +
        "writes: #{writes}\n" +
        "time_io: #{time_io}\n" +
        "time_reading: #{time_reading}\n" +
        "time_writing: #{time_writing}\n" +
        "in_progress: #{in_progress}\n" +
        "kb_written: #{kb_written}\n" +
        "kb_read: #{@kb_read}"
  end
end



class BlockIOStat
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

  def initialize(filename, bytes_per_sector)
    words = File.read(filename).split
    @reads = words[0].to_i
    @read_bytes = words[2].to_i * bytes_per_sector
    @read_time_ms = words[3].to_i
    @writes = words[4].to_i
    @write_bytes = words[6].to_i * bytes_per_sector
    @write_time_ms = words[7].to_i
    @in_progress = words[8].to_i
    @active_time_ms = words[9].to_i
    @queue_time_ms = words[10].to_i
  end

end
