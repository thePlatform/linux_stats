
# The MIT License (MIT)
#
# Copyright (c) 2015-16 Comcast Technology Solutions
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

module LinuxStats::OS::CPU
  module Column
    USER = 1
    NICE = 2
    SYSTEM = 3
    IDLE = 4
    IO_WAIT = 5
    IRQ = 6
    SOFT_IRQ = 7
    STEAL = 8
  end

  DATA_FILE = '/proc/stat'

  class Reporter
    def initialize(data = nil)
      set_stats data
    end

    def report(elapsed_time=nil, data=nil)
      prev_stats = @current_stats
      prev_timestamp = @current_timestamp
      set_stats data
      @current_timestamp = Time.now()
      elapsed_time = @current_timestamp - prev_timestamp unless elapsed_time
      ret = {}
      ret[:cpus] = {}
      @current_stats[:cpu].keys.each do |cpu_name|
        ret[:cpus][cpu_name] = @current_stats[:cpu][cpu_name].report(prev_stats[:cpu][cpu_name])
      end
      ret[:os] = {}
      ret[:os][:interrupts_persec] =
          (@current_stats[:interrupts] - prev_stats[:interrupts]) / elapsed_time
      ret[:os][:ctxt_switches_persec] =
          (@current_stats[:context_switches] - prev_stats[:context_switches]) / elapsed_time
      ret[:os][:procs_running] = @current_stats[:procs_running]
      ret[:os][:procs_blocked] = @current_stats[:procs_blocked]
      ret
    end

    def set_stats(proc_stat_data = nil)
      proc_stat_data = File.read(DATA_FILE) unless proc_stat_data
      @current_timestamp = Time.now
      @current_stats = {}
      @current_stats[:cpu] = {}
      proc_stat_data.each_line do |line|
        @current_stats[:interrupts] = line.split[1].to_i if line =~ /^intr/
        @current_stats[:context_switches]= line.split[1].to_i if line =~ /^ctxt/
        @current_stats[:procs_running] = line.split[1].to_i if line =~ /^procs_running/
        @current_stats[:procs_blocked] = line.split[1].to_i if line =~ /^procs_blocked/
        if line =~ /^cpu/
          cpu_stat = CPUData.new line
          @current_stats[:cpu][cpu_stat.name] = cpu_stat
        end
      end
    end
  end

  class CPUData
    # ingests a line from /proc/stat into a os structure of CPU
    # usage values

    attr_reader :idle,
                :iowait,
                :irq,
                :name,
                :nice,
                :softirq,
                :steal,
                :system,
                :total_jiffies,
                :user

    def initialize(stat_line)
      # The meanings of the columns are as follows, from left to right:
      #    [1] user: normal processes executing in user mode
      #    [2] nice: niced processes executing in user mode
      #    [3] system: processes executing in kernel mode
      #    [4] idle: twiddling thumbs
      #    [5] iowait: waiting for I/O to complete
      #    [6] irq: servicing interrupts
      #    [7] softirq: servicing softirqs
      #    [8] steal

      words = stat_line.split
      @name = words[0]
      @name = 'all' if @name == 'cpu'
      @total_jiffies = 0
      words.slice(1, words.length).each do |stat|
        @total_jiffies += stat.to_i
      end
      # get jiffies spent in each state
      @idle = words[Column::IDLE].to_i
      @iowait = words[Column::IO_WAIT].to_i
      @irq = words[Column::IRQ].to_i
      @nice = words[Column::NICE].to_i
      @softirq = words[Column::SOFT_IRQ].to_i
      @steal = words[Column::STEAL].to_i
      @system = words[Column::SYSTEM].to_i
      @user = words[Column::USER].to_i
    end

    def report(prev = nil)
      report = {}
      return report unless prev
      # calculate avgs since the last snapshot
      elapsed_jiffies = total_jiffies - prev.total_jiffies
      report[:idle_pct] = 100.0 * (idle - prev.idle) / elapsed_jiffies
      report[:iowait_pct] = 100.0 * (iowait - prev.iowait) / elapsed_jiffies
      report[:irq_pct] = 100.0 * (irq - prev.irq) / elapsed_jiffies
      report[:nice_pct] = 100.0 * (nice - prev.nice) / elapsed_jiffies
      report[:softirq_pct] = 100.0 * (softirq - prev.softirq) / elapsed_jiffies
      report[:steal_pct] = 100.0 * (steal - prev.steal) / elapsed_jiffies
      report[:system_pct] = 100.0 * (system - prev.system) / elapsed_jiffies
      report[:used_pct] = 100.0 - report[:idle_pct]
      report[:user_pct] = 100.0 * (user - prev.user) / elapsed_jiffies
      report
    end

    private

    def sum_of_stats(report)
      # these should all add to 100% or very near.
      tot = report[:user_pct]
      tot += report[:nice_pct]
      tot += report[:system_pct]
      tot += report[:idle_pct]
      tot += report[:iowait_pct]
      tot += report[:irq_pct]
      tot += report[:softirq_pct]
      tot += report[:steal]
      tot
    end
  end

end
