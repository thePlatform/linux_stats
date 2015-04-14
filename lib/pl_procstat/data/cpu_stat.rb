module Procstat::CPU
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

  class Stats

    # ingests a line from /proc/stat into a data structure of CPU
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

    def report(prev=nil)
      report = {}
      return report unless prev
      # calculate avgs since the last snapshot
      elapsed_jiffies = total_jiffies - prev.total_jiffies
      report[:idle_pct] = 100.0*(idle-prev.idle)/elapsed_jiffies
      report[:iowait_pct] = 100.0*(iowait-prev.iowait)/elapsed_jiffies
      report[:irq_pct] = 100.0*(irq-prev.irq)/elapsed_jiffies
      report[:nice_pct] = 100.0*(nice-prev.nice)/elapsed_jiffies
      report[:softirq_pct] = 100.0*(softirq-prev.softirq)/elapsed_jiffies
      report[:steal_pct] = 100.0*(steal-prev.steal)/elapsed_jiffies
      report[:system_pct] = 100.0*(system-prev.system)/elapsed_jiffies
      report[:used_pct] = 100.0 - report[:idle_pct]
      report[:user_pct] = 100.0*(user-prev.user)/elapsed_jiffies
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
      tot +=report[:irq_pct]
      tot += report[:softirq_pct]
      tot += report[:steal]
      tot
    end
  end
end