require 'time'

CPU_DATA_FILE = '/proc/stat'
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
  #   * be as fast and lightweight
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

  attr_reader :proc_names,
              :start_time

  attr_accessor :last_called_time,
                :last_cpu_data

  def initialize(proc_names=[])
    @proc_names = proc_names
    @start_time = Time.now
    @last_called_time = start_time
    @last_cpu_data = nil
    proc_names.each do |proc_name|
      puts "Monitoring #{proc_name}"
    end
  end

  def pids(cmd)
    pid_list = []
    Dir['/proc/[0-9]*/cmdline'].each do |p|
      pid_list.push(p.split('/')[PID_INDEX]) if File.read(p).match(cmd)
    end
    pid_list
  end

  def report
    report_start_time = Time.now
    puts "Total elapsed seconds: #{Time.now - start_time}"
    puts "Seconds since last call: #{Time.now - last_called_time}"
    proc_names.each do |proc_name|
      puts "Proc: #{proc_name}"
      pids(proc_name).each do |pid|
        puts "  - #{pid}"
      end
    end
    puts cpu_summary
    @last_called_time = Time.now
    puts "CPU report took #{Time.now-report_start_time} seconds."
  end


  private


  def cpu_summary
    cpu_report = {}
    cpu_data = {}
    total_interrupts = 0
    total_context_switches = 0
    # get current data
    IO.readlines(CPU_DATA_FILE).each do |line|
      if line =~ /^cpu/
        cpu_stat = CPUStat.new line
        cpu_data[cpu_stat.name] = cpu_stat
      end
      if line =~ /^/

      end
    end

    # generate report by comparing current data to prev data
    cpu_data.keys.each do |cpu_name|
      if last_cpu_data
        cpu_report[cpu_name] = cpu_data[cpu_name].report(last_cpu_data[cpu_name])
      end
    end
    # set things up for the next iteration
    @last_cpu_data = cpu_data
    cpu_report
  end

  def disk_io

  end

  def disk_storage

  end

  def net

  end

  def memory

  end

end
