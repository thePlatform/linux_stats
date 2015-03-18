require 'time'
require 'pp'

CPU_DATA_FILE = '/proc/stat'
FILE_DESCRIPTOR_DATA_FILE = '/proc/sys/fs/file-nr'
INITIAL_SLEEP_SECONDS = 1
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
PID_INDEX = 2
SWAP_TOTAL = 'SwapTotal'
SWAP_FREE = 'SwapFree'


class LinuxOSStats

  #
  # sys-proctable may provide the functionality we need, or some of it.
  # check out  https://github.com/djberg96/sys-proctable
  #
  # Proof of concept for gathering useful OS-level statistics from the /proc
  # filesystem.
  #
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
              :last_called_time,
              :last_cpu_data,
              :last_net_data,
              :last_procstat_data,
              :mounted_partitions,
              :proc_names,
              :start_time

  def initialize
    @blocks_per_kilobyte = 4 # TODO: calculate from info in /proc?  Where?
    @proc_names = proc_names
    @start_time = Time.now
    @last_called_time = start_time
    @last_cpu_data = nil
    @last_net_data = nil
    @last_procstat_data = nil
    @mounted_partitions = mounts
  end

  def pids(cmd)
    pid_list = []
    Dir['/proc/[0-9]*/cmdline'].each do |p|
      pid_list.push(p.split('/')[PID_INDEX]) if File.read(p).match(cmd)
    end
    pid_list
  end

  def report
    #puts "Total elapsed seconds: #{Time.now - start_time}"
    #puts "Seconds since last call: #{Time.now - last_called_time}"
    os_perf_stats = {}
    os_perf_stats[:cpu] = cpu_summary
    os_perf_stats[:net] = net
    os_perf_stats[:partition_use] = disk_storage
    os_perf_stats[:load_avg] = load_avg
    os_perf_stats[:file_descriptor] = open_files
    os_perf_stats[:memory] = memory
    @last_called_time = Time.now
    os_perf_stats
  end


  private


  def cpu_summary
    cpu_report = {}
    cpu_data = {}
    procstat_data = {}
    # get current data
    IO.readlines(CPU_DATA_FILE).each do |line|
      if line =~ /^cpu/
        cpu_stat = CPUStat.new line
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
    net_data = {}
    net_report = {}
    IO.readlines(NET_BANDWIDTH_DATA_FILE).each do |line|
      if line =~ /^ *eth/
        net_stat = NetStat.new(line)
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


  def disk_io
    # iops
    # bytes
    # bandwidth capacity %
  end

  def disk_storage
    storage_report = {}
    mounted_partitions.each do |partition|
      usage = partition_used(partition)
      storage_report[partition] = {}
      storage_report[partition][:used] = usage[0]
      storage_report[partition][:total] = usage[1]
    end
    storage_report
  end

  def memory
    # There is a bunch more stuff available in /proc/meminfo than we're using
    # here, so we have the option to pull in many additional metrics.
    mem_report = {}
    IO.readlines(MEMORY_DATA_FILE).each do |line|
      if line =~ /^#{MEM_TOTAL}/
        puts line.split[1], line.split[1].to_i
        #mem_report[:mem_total] = line.split()[1].to_i
      end
      if line =~ /^#{MEM_FREE}/
        #mem_report[:mem_free] = line.split()[1].to_i
      end
      if line =~ /^#{SWAP_TOTAL}/
        #mem_report[:swap_total] = line.split()[1].to_i
      end
      if line =~ /^#{SWAP_FREE}/
        #mem_report[:swap_free] = line.split()[1].to_i
      end
      mem_report
    end
  end

  def load_avg
    load_report = {}
    data = File.read(LOAD_AVG_DATA_FILE).split
    load_report[:one] = data[0].to_f
    load_report[:five] = data[1].to_f
    load_report[:fifteen] = data[2].to_f
    load_report
  end

  def open_files
    file_descriptors = {}
    data = File.read(FILE_DESCRIPTOR_DATA_FILE).split
    file_descriptors[:used] = data[0].to_i
    file_descriptors[:max] = data[2].to_i
    file_descriptors
  end

  # see https://www.ruby-forum.com/topic/4416522
  # returns: array of partition use: [
  #   <used kilobytes>
  #   <max kilobytes>
  # ]
  # Calls to statvfs may be useful too
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
end
