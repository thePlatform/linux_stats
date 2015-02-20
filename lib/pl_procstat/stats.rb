require 'time'
require 'pp'

CPU_DATA_FILE = '/proc/stat'
NET_BANDWIDTH_DATA_FILE = '/proc/net/dev'
INITIAL_SLEEP_SECONDS = 1
PID_INDEX = 2


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
  #   * gather all data in 1ms or less
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

  attr_reader :last_called_time,
              :last_cpu_data,
              :last_net_data,
              :last_procstat_data,
              :proc_names,
              :start_time

  def initialize
    @proc_names = proc_names
    @start_time = Time.now
    @last_called_time = start_time
    @last_cpu_data = nil
    @last_net_data = nil
    @last_procstat_data = nil
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
      end
      IO.readlines('/proc/net/sockstat').each do |line|
        if line =~ /^TCP/
          words = line.split()
          net_report[:tcp_open_conn] = words[2].to_i
          net_report[:tcp_timewait_conn] = words[6].to_i
        end
      end
    end
    @last_net_data = net_data
    net_report

    #TODO: open connection counts from /proc/net/sockstat

  end


  def disk_io
    # iops
    # bytes
    # bandwidth capacity %
  end

  def disk_storage
    # bytes
    # capacity %
  end


  def memory
    # /proc/meminfo (?)
    # ram
    # swap
  end

  def load_avg
    # 1
    # 5
    # 15
  end

  def open_files
    # number of open files
  end

end
