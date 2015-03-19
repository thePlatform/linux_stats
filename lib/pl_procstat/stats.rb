require 'time'
require 'pp'

CPU_DATA_FILE = '/proc/stat'
CPUINFO_DATA_FILE = '/proc/cpuinfo'
DISK_STATS_DATA_FILE = '/proc/diskstats'
FILE_DESCRIPTOR_DATA_FILE = '/proc/sys/fs/file-nr'
INITIAL_SLEEP_SECONDS = 1
IGNORE_DISKS = [
    '^dm-[0-9]',
    '^fd[0-9]',
    '^ram',
    '^loop',
    '^sr',
    '^sd.*[0-9]'
]
IGNORE_PARTITIONS = [
    '^\/proc',
    '^\/sys',
    'docker'
]
LOAD_AVG_DATA_FILE = '/proc/loadavg'
MEM_TOTAL = 'MemTotal'
MEM_FREE = 'MemFree'
MEMORY_DATA_FILE = '/proc/meminfo'
MOUNTS_DATA_FILE = '/proc/mounts'
NET_BANDWIDTH_DATA_FILE = '/proc/net/dev'
NET_SOCKETS_DATA_FILE = '/proc/net/sockstat'
PAGE_CACHE = 'Cached'
PID_INDEX = 2
# FIXME: this should be set on a per-device basis with a map of
#        device name to sector data size
SECTOR_SIZE_DATA_FILE = '/sys/block/sda/queue/hw_sector_size'
SWAP_TOTAL = 'SwapTotal'
SWAP_FREE = 'SwapFree'


class LinuxOSStats

  #
  # sys-proctable may provide the functionality we need, or some of it.
  # check out  https://github.com/djberg96/sys-proctable
  #
  # Goals:
  #   * be as fast and lightweight as possible
  #   * gather all data in 2ms or less
  #   * no shelling out to existing system tools (sar, vmstat, etc.) since we
  #     don't want the expense of creating a new process.
  #   * provide useful statistics in the form of a sensible hash that clients 
  #     can inspect as desired.
  #
  # Goal number two seems to require us to get our data by inspecting the /proc 
  # filesystem.

  # Other ruby tools exist for getting CPU data, etc.  Unfortunately they all 
  # seem to rely on shelling out to native system tools as the basis for 
  # retrieving their underlying data.
  #
  # By going directly to /proc, we have a higher level of control of the type 
  # of data we make available.
  #
  #
  # Resources:
  #  * http://stackoverflow.com/questions/16726779/total-cpu-usage-of-an-application-from-proc-pid-stat
  #  * http://stackoverflow.com/questions/1420426/calculating-cpu-usage-of-a-process-in-linux
  #  * http://stackoverflow.com/questions/3017162/how-to-get-total-cpu-usage-in-linux-c/3017438
  #
  #

  attr_reader :blocks_per_kilobyte,
              :bytes_per_disk_sector,
              :last_called_time,
              :last_cpu_data,
              :last_net_data,
              :last_procstat_data,
              :mounted_partitions,
              :num_cpu,
              :proc_names,
              :start_time,
              :watched_disks

  def initialize
    @start_time = Time.now

    @blocks_per_kilobyte = 4 # TODO: calculate from info in /proc?  Where?
    @bytes_per_disk_sector = sector_size
    @last_called_time = start_time
    @last_cpu_data = nil
    @last_net_data = nil
    @last_procstat_data = nil
    @mounted_partitions = mounts
    @proc_names = proc_names
    @watched_disks = disks
    @num_cpu = cpuinfo
  end

  def pids(cmd)
    pid_list = []
    Dir['/proc/[0-9]*/cmdline'].each do |p|
      pid_list.push(p.split('/')[PID_INDEX]) if File.read(p).match(cmd)
    end
    pid_list
  end

  def report
    os_perf_stats = {}
    os_perf_stats[:cpu] = cpu_summary
    os_perf_stats[:net] = net
    os_perf_stats[:partition_use] = disk_storage
    os_perf_stats[:load_avg] = load_avg
    os_perf_stats[:file_descriptor] = open_files
    os_perf_stats[:memory] = memory
    os_perf_stats[:disk_io] = disk_io_blockstats
    @last_called_time = Time.now
    os_perf_stats
  end


  private


  def cpu_summary
    # execution time: 0.6 ms  [MEDIUM]
    cpu_report = {}
    cpu_data = {}
    procstat_data = {}
    # get current data
    IO.readlines(CPU_DATA_FILE).each do |line|
      if line =~ /^cpu/
        cpu_stat = CPU::Stats.new line
        cpu_data[cpu_stat.name] = cpu_stat
      end
      procstat_data[:interrupts] = line.split()[1].to_i if line =~ /^intr/
      procstat_data[:context_switches]= line.split()[1].to_i if line =~/^ctxt/
      if line =~/^procs_running/
        cpu_report[:procs_running] = line.split()[1].to_i
      end
      if line =~/^procs_blocked/
        cpu_report[:procs_blocked] = line.split()[1].to_i
      end
    end
    elapsed_time = Time.now - last_called_time
    # generate report by comparing current data to prev data
    if last_cpu_data
      cpu_data.keys.each do |cpu_name|
        cpu_report[cpu_name] = cpu_data[cpu_name].report(last_cpu_data[cpu_name])
      end
      cpu_report[:interrupts_persec] =
          (procstat_data[:interrupts] - last_procstat_data[:interrupts])/ elapsed_time
      cpu_report[:ctxt_switches_persec] =
          (procstat_data[:context_switches]-last_procstat_data[:context_switches]) / elapsed_time

    end
    # set things up for the next iteration
    @last_cpu_data = cpu_data
    @last_procstat_data = procstat_data
    cpu_report
  end

  def net
    # execution time: 1.1 ms.  [HIGH]
    net_data = {}
    net_report = {}
    IO.readlines(NET_BANDWIDTH_DATA_FILE).each do |line|
      if line =~ /^ *eth/
        net_stat = Net::Stats.new(line)
        net_data[net_stat.interface] = net_stat
      end
    end
    elapsed_time = Time.now - last_called_time
    if last_net_data
      net_data.keys.each do |interface|
        net_report[interface] = {}
        net_report[interface][:tx_bytes_persec] =
            (net_data[interface].bytes_tx - last_net_data[interface].bytes_tx)/ elapsed_time
        net_report[interface][:rx_bytes_persec] =
            (net_data[interface].bytes_rx-last_net_data[interface].bytes_rx)/elapsed_time
        net_report[interface][:errors_rx_persec] =
            (net_data[interface].errors_rx-last_net_data[interface].errors_rx)/elapsed_time
        net_report[interface][:errors_tx_persec] =
            (net_data[interface].errors_tx-last_net_data[interface].errors_tx)/elapsed_time
      end
      IO.readlines(NET_SOCKETS_DATA_FILE).each do |line|
        if line =~ /^TCP/
          words = line.split()
          net_report[:tcp_open_conn] = words[2].to_i
          net_report[:tcp_timewait_conn] = words[6].to_i
        end
      end
    end
    @last_net_data = net_data
    net_report
  end

  # NEW
  def disk_io_blockstats
    # execution time: 0.24 ms  [LOW]
    all_disk_report = {}
    disk_stats = {}
    elapsed_time = Time.now - last_called_time
    watched_disks.each do |disk_name|
      data = File.read("/sys/block/#{disk_name}/stat")
      stats = BlockIO::Stats.new(data, bytes_per_disk_sector)
      disk_stats[disk_name] = stats
      disk_report = {}
      disk_report[:in_progress] = stats.in_progress
      if @last_disk_stats
        last = @last_disk_stats[disk_name]
        disk_report[:reads_persec] = (stats.reads - last.reads) / elapsed_time
        disk_report[:writes_persec] = (stats.writes - last.writes) / elapsed_time
        disk_report[:bytes_read_persec] = (stats.read_bytes - last.read_bytes) / elapsed_time
        disk_report[:bytes_written_persec] = (stats.write_bytes - last.write_bytes) / elapsed_time
        cpu_ms = elapsed_time * num_cpu * 1.25
        pct_active = (stats.active_time_ms - last.active_time_ms) / cpu_ms
        # pct_active is an approximation, which may occasionally be a bit over 100%.  We
        # cap it here at 100 to avoid confusion
        pct_active = 100 if pct_active > 100
        disk_report[:percent_active] = pct_active
      end
      all_disk_report[disk_name] = disk_report
    end
    @last_disk_stats = disk_stats
    all_disk_report
  end


  def disk_storage
    # execution time: 0.3 ms  [LOW]
    storage_report = {}
    mounted_partitions.each do |partition|
      usage = partition_used(partition)
      storage_report[partition] = {}
      storage_report[partition][:total_kb] = usage[0]
      storage_report[partition][:available_kb] = usage[1]
    end
    storage_report
  end

  def memory
    # execution time: 2.4 ms  [VERY HIGH]
    #
    # There is a bunch more stuff available in /proc/meminfo than we're using
    # here, so we have the option to pull in many additional metrics.  This is
    # a relatively expensive call, it more than doubles the execution time of
    # of an entire stats gathering iteration.  (possibly because /proc/meminfo
    # is a large file)
    #
    # TODO: investigate using syscall to get this more cheaply
    # TODO: include page_cache info
    mem_report = {}
    IO.readlines(MEMORY_DATA_FILE).each do |line|
      if line =~ /^#{MEM_TOTAL}/
        #puts line.split[1], line.split[1].to_i
        mem_report[:mem_total_kb] = line.split()[1].to_i
        next
      end
      if line =~ /^#{MEM_FREE}/
        mem_report[:mem_free_kb] = line.split()[1].to_i
        next
      end
      if line =~ /^#{PAGE_CACHE}/
        mem_report[:page_cache_kb] = line.split()[1].to_i
        next
      end
      if line =~ /^#{SWAP_TOTAL}/
        mem_report[:swap_total_kb] = line.split()[1].to_i
        next
      end
      if line =~ /^#{SWAP_FREE}/
        mem_report[:swap_free_kb] = line.split()[1].to_i
        next
      end
    end
    mem_report
  end

  def load_avg
    # execution time: 0.12 ms  [LOW]
    load_report = {}
    data = File.read(LOAD_AVG_DATA_FILE).split
    load_report[:one] = data[0].to_f
    load_report[:five] = data[1].to_f
    load_report[:fifteen] = data[2].to_f
    load_report
  end

  # for description of file-nr info, see
  # https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/5/html/Tuning_and_Optimizing_Red_Hat_Enterprise_Linux_for_Oracle_9i_and_10g_Databases/chap-Oracle_9i_and_10g_Tuning_Guide-Setting_File_Handles.html
  def open_files
    # execution time: 0.1 ms  [LOW]
    file_descriptors = {}
    data = File.read(FILE_DESCRIPTOR_DATA_FILE).split
    allocated = data[0].to_i
    available = data[1].to_i
    # for kernels 2.4 and below, 'used' is just data[0].  We could detect kernel version
    # from /proc/version and handle old versions, but Centos 5 and 6 all have kernels
    # 2.6 and above
    file_descriptors[:used] = allocated - available
    file_descriptors[:max] = data[2].to_i
    file_descriptors
  end


  ## below here are util functions which we can factor out into a new module


  # see https://www.ruby-forum.com/topic/4416522
  # returns: array of partition use: [
  #   <used kilobytes>
  #   <max kilobytes>
  # ]
  def partition_used(partition)
    b=' '*128
    syscall(137, partition, b)
    a=b.unpack('QQQQQ')
    [a[2]*blocks_per_kilobyte, a[4]*blocks_per_kilobyte]
  end

  def mounts
    mount_list = []
    IO.readlines(MOUNTS_DATA_FILE).each do |line|
      mount = line.split[1]
      next if IGNORE_PARTITIONS.include? mount
      mount_list.push line.split[1].strip
    end
    IGNORE_PARTITIONS.each do |partition|
      mount_list.reject! { |x| x =~ /#{partition}/ }
    end
    mount_list
  end

  def disks
    disk_list = []
    IO.readlines(DISK_STATS_DATA_FILE).each do |line|
      words = line.split
      disk_list.push words[2]
    end
    IGNORE_DISKS.each do |pattern|
      disk_list.reject! { |x| x =~ /#{pattern}/ }
    end
    disk_list
  end

  def sector_size
    begin
      return File.read(SECTOR_SIZE_DATA_FILE).strip().to_i
    rescue
      # handle CentOS 5
      return 512
    end
  end

  def cpuinfo
    ret = 0
    IO.readlines(CPUINFO_DATA_FILE).each do |line|
      ret += 1 if line =~ /^processor/
    end
    ret
  end
end
