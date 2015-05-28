
# The MIT License (MIT)
#
# Copyright (c) 2015 ThePlatform for Media
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

module LinuxStats::PID::PidStat

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

  # maps PIDS to LinuxStats::PID::PidStat::Stat objects
  @@pid_stats_map={}


  # Given a PidStatData instance, calculates additional time-based metrics
  class Stat

    attr_accessor :boot_time,
                  :jiffies_per_sec,
                  :page_size_bytes,
                  :perf_detail,
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

    def record(data=nil)
      prev_stats = @current_stats
      prev_timestamp = @current_timestamp
      set_stats data
      elapsed_seconds = @current_timestamp - prev_timestamp
      elapsed_jiffies = jiffies_per_sec * elapsed_seconds
      @perf_detail = {}
      @perf_detail[:cpu] = {}
      proc_self = {
          guest_pct: 100.0*(@current_stats.se_guest - prev_stats.se_guest)/elapsed_jiffies,
          kern_pct: 100.0*(@current_stats.se_kernel - prev_stats.se_kernel)/elapsed_jiffies,
          user_pct: 100.0*(@current_stats.se_user - prev_stats.se_user)/elapsed_jiffies
      }
      @perf_detail[:cpu][:self] = proc_self
      proc_child = {
          guest_pct: 100.0*(@current_stats.ch_guest - prev_stats.ch_guest)/elapsed_jiffies,
          kern_pct: 100.0*(@current_stats.ch_kernel - prev_stats.ch_kernel)/elapsed_jiffies,
          user_pct: 100.0*(@current_stats.ch_user - prev_stats.ch_user)/elapsed_jiffies
      }
      @perf_detail[:cpu][:child] = proc_child
      @perf_detail[:cpu][:total] = {
          guest_pct: proc_child[:guest_pct] + proc_self[:guest_pct],
          kern_pct: proc_child[:kern_pct] + proc_self[:kern_pct],
          user_pct: proc_child[:user_pct] + proc_self[:user_pct],
      }
      @perf_detail[:mem] = {
          resident_set_bytes: @current_stats.resident_set_pages * page_size_bytes,
          virtual_mem_bytes: @current_stats.virtual_mem_bytes
      }
      @perf_detail[:threads] = @current_stats.threads
      start_time = @current_stats.start_time/jiffies_per_sec + boot_time
      @perf_detail[:age_seconds] = Time.now.to_i - start_time
    end

    private

    def read_boot_time
      File.readlines('/proc/stat').each do |line|
        return line.split[1].to_i if line =~ /^btime/
      end
    end

  end

  # object to hold performance statistics for a single pid, derived from
  # /proc/<pid>/stat
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

  end


  # One reporter instance will be assigned
  class Reporter

    attr_accessor :pid_stats_map

    def initialize
      @pid_stats_map = {}
    end

    # gather performance data for a single PID
    def record(pid, data=nil)
      pid_stats_map[pid] = Stat.new(pid, data) unless pid_stats_map[pid]
      pid_stats_map[pid].record
    end

    # Roll up the stats from individual PIDs into a summary
    def report
      ret = {}
      return ret if pid_stats_map.size == 0
      age_sec = 0
      cpu_pct = 0
      resident_set_bytes = 0
      threads=0
      virtual_mem_bytes = 0
      pid_stats_map.each do |pid, stat|
        age_sec += stat.perf_detail[:age_seconds]
        threads += stat.perf_detail[:threads]
        resident_set_bytes += stat.perf_detail[:mem][:resident_set_bytes]
        virtual_mem_bytes += stat.perf_detail[:mem][:virtual_mem_bytes]
        cpu_pct += stat.perf_detail[:cpu][:self][:user_pct]
        cpu_pct += stat.perf_detail[:cpu][:self][:kern_pct]
        cpu_pct += stat.perf_detail[:cpu][:self][:guest_pct]
      end
      ret[:age_seconds] = age_sec
      ret[:threads] = threads
      ret[:mem] = {}
      ret[:mem][:resident_set_bytes] = resident_set_bytes
      ret[:mem][:virtual_mem_bytes] = virtual_mem_bytes
      ret[:cpu_pct] = cpu_pct
      ret
    end
  end
end
