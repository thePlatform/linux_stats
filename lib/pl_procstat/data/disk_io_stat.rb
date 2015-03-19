module BlockIO

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
  class Stats
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
