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


end
