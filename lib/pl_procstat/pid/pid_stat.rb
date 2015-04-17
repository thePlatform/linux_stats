require 'pl_procstat'

module Procstat::PID::PidStat

  module Column
    CHILD_GUEST = 43
    CHILD_KERNEL = 16
    CHILD_USER = 15
    COMMAND = 1
    RESIDENT_SET_SIZE = 23
    SELF_GUEST = 42
    SELF_KERNEL = 14
    SELF_USER = 13
    START_TIME = 21
    THREADS = 19
    VMEM_SIZE = 22
  end

  @@stats={}


  class Stat

    attr_accessor :boot_time,
                  :jiffies_per_sec,
                  :page_size_bytes,
                  :pid

    def initialize(pid, data=nil)
      @pid = pid
      @boot_time = read_boot_time
      @jiffies_per_sec = `getconf CLK_TCK`.to_f
      @page_size_bytes = `getconf PAGESIZE`.to_i
      set_stats data
    end

    def set_stats(data=nil)
      @current_stats = PidStatData.new(@pid, data)
      @current_timestamp = Time.now()
    end

    def report(data=nil)
      prev_stats = @current_stats
      prev_timestamp = @current_timestamp
      set_stats data
      elapsed_seconds = @current_timestamp - prev_timestamp
      elapsed_jiffies = jiffies_per_sec * elapsed_seconds
      ret = {}
      # puts "current: #{@current_stats}"
      # puts "pref: #{prev_stats}"
      ret[:cpu] = {}
      proc_self = {
          guest_pct: 100.0*(@current_stats.se_guest - prev_stats.se_guest)/elapsed_jiffies,
          kern_pct: 100.0*(@current_stats.se_kernel - prev_stats.se_kernel)/elapsed_jiffies,
          user_pct: 100.0*(@current_stats.se_user - prev_stats.se_user)/elapsed_jiffies
      }
      ret[:cpu][:self] = proc_self
      proc_child = {
          guest_pct: 100.0*(@current_stats.ch_guest - prev_stats.ch_guest)/elapsed_jiffies,
          kern_pct: 100.0*(@current_stats.ch_kernel - prev_stats.ch_kernel)/elapsed_jiffies,
          user_pct: 100.0*(@current_stats.ch_user - prev_stats.ch_user)/elapsed_jiffies
      }
      ret[:cpu][:child] = proc_child
      ret[:cpu][:total] = {
          guest_pct: proc_child[:guest_pct] + proc_self[:guest_pct],
          kern_pct: proc_child[:kern_pct] + proc_self[:kern_pct],
          user_pct: proc_child[:user_pct] + proc_self[:user_pct],
      }
      ret[:mem] = {
          resident_set_bytes: @current_stats.resident_set_pages * page_size_bytes,
          virtual_mem_bytes: @current_stats.virtual_mem_bytes
      }
      ret[:threads] = @current_stats.threads
      start_time = @current_stats.start_time/jiffies_per_sec + boot_time
      ret[:age_seconds] = Time.now.to_i - start_time
      ret
    end

    private

    def read_boot_time
      File.readlines('/proc/stat').each do |line|
        return line.split[1].to_i if line =~ /^btime/
      end
    end

  end

  class PidStatData

    attr_accessor :ch_guest,
                  :ch_kernel,
                  :ch_user,
                  :cmd,
                  :pid,
                  :resident_set_pages,
                  :se_guest,
                  :se_kernel,
                  :se_user,
                  :start_time,
                  :threads,
                  :tot_guest,
                  :tot_kernel,
                  :tot_user,
                  :virtual_mem_bytes

    def initialize(pid, data=nil)
      #puts "data nil? #{data.nil?}"
      data = File.read("/proc/#{pid}/stat") unless data
      #puts "Data: #{data}"
      words = data.split
      @cmd = words[Column::COMMAND].tr(')(', '')
      @ch_guest = words[Column::CHILD_GUEST].to_i
      @ch_kernel = words[Column::CHILD_KERNEL].to_i
      @ch_user = words[Column::CHILD_USER].to_i
      @resident_set_pages = words[Column::RESIDENT_SET_SIZE].to_i
      @se_guest = words[Column::SELF_GUEST].to_i
      @se_kernel = words[Column::SELF_KERNEL].to_i
      @se_user = words[Column::SELF_USER].to_i
      @start_time = words[Column::START_TIME].to_i
      @threads = words[Column::THREADS].to_i
      @tot_guest = @ch_guest + @se_guest
      @tot_kernel = @ch_kernel + @se_kernel
      @tot_user = @ch_user + @se_user
      @virtual_mem_bytes = words[Column::VMEM_SIZE].to_i
    end

    def to_s
      "
cmd: #{cmd}
ch_guest: #{ch_guest}
ch_kern: #{ch_kernel}
ch_user: #{ch_user}
se_guest: #{se_guest}
se_kern: #{se_kernel}
se_usr: #{se_user}
tot_guest: #{tot_guest}
tod_kern: #{tot_kernel}
tot_usr: #{tot_user}

"
    end

  end

  # ensures we're tracking a given pid with all our handlers.  If
  # the pid is tracked already, this is a no-op
  def self.init(pid, data=nil)
    @@stats[pid] = Stat.new(pid, data)  unless @@stats[pid]
  end

  def self.report(pid)
    @@stats[pid].report
  end

end
