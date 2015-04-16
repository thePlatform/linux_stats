require 'pl_procstat'

module Procstat::PID::Procstat

  module Column
    CHILD_GUEST = 43
    CHILD_KERNEL = 16
    CHILD_USER = 15
    COMMAND = 1
    SELF_GUEST = 42
    SELF_KERNEL = 14
    SELF_USER = 13
  end

  # TODO: this is almost universally 100, but we ought to get this via sysconf(_SC_CLK_TCK)
  JIFFIES_PERSEC = 100.0

  class Stat

    attr_accessor :pid

    def initialize(pid, data=nil)
      set_stats data
      @pid = pid
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
      elapsed_jiffies = JIFFIES_PERSEC * elapsed_seconds
      ret = {}
      ret[:name] = "#{@current_stats.cmd}_#{pid}"
      puts "current: #{@current_stats}"
      puts "pref: #{prev_stats}"
      ret[:cpu] = {}
      proc_self = {
          [:guest_pct] => 100.0*(@current_stats.se_guest - prev_stats.se_guest)/elapsed_jiffies,
          [:kern_pct] => 100.0*(@current_stats.se_kernel - prev_stats.se_kernel)/elapsed_jiffies,
          [:user_pct] => 100.0*(@current_stats.se_user - prev_stats.se_user)/elapsed_jiffies
      }
      ret[:cpu][:self] = proc_self
      proc_child = {
          [:guest_pct] => 100.0*(@current_stats.ch_guest - prev_stats.ch_guest)/elapsed_jiffies,
          [:kern_pct] => 100.0*(@current_stats.ch_kernel - prev_stats.ch_kernel)/elapsed_jiffies,
          [:user_pct] => 100.0*(@current_stats.ch_user - prev_stats.ch_user)/elapsed_jiffies
      }
      ret[:cpu][:child] = proc_child
      # ret[:cpu][:total] = {
      #     [:guest_pct] => proc_child[:guest_pct] + proc_self[:guest_pct],
      #     [:kern_pct] => proc_child[:kern_pct] + proc_self[:kern_pct],
      #     [:user_pct] => proc_child[:user_pct] + proc_self[:user_pct],
      # }
      ret
    end
  end

  class PidStatData

    attr_accessor :ch_guest,
                  :ch_kernel,
                  :ch_user,
                  :cmd,
                  :pid,
                  :se_guest,
                  :se_kernel,
                  :se_user,
                  :tot_guest,
                  :tot_kernel,
                  :tot_user

    def initialize(pid, data=nil)
      puts "data nil? #{data.nil?}"
      data = File.read("/proc/#{pid}/stat") unless data
      puts data
      words = data.split
      @cmd = words[Column::COMMAND].tr(')(', '')
      @ch_guest = words[Column::CHILD_GUEST].to_i
      @ch_kernel = words[Column::CHILD_KERNEL].to_i
      @ch_user = words[Column::CHILD_USER].to_i
      @se_guest = words[Column::SELF_GUEST].to_i
      @se_kernel = words[Column::SELF_KERNEL].to_i
      @se_user = words[Column::SELF_USER].to_i
      @tot_guest = @ch_guest + @se_guest
      @tot_kernel = @ch_kernel + @se_kernel
      @tot_user = @ch_user + @se_user
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

end
