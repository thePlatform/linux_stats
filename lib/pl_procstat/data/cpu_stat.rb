class CPUStat

  # ingests a line from /proc/stat into a data structure of CPU
  # usage values

  attr_reader :user,
              :nice,
              :system,
              :idle,
              :iowait,
              :irq,
              :softirq,
              :name,
              :total_jiffies

  def initialize(stat_line)

    # The meanings of the columns are as follows, from left to right:
    #    [1] user: normal processes executing in user mode
    #    [2] nice: niced processes executing in user mode
    #    [3] system: processes executing in kernel mode
    #    [4] idle: twiddling thumbs
    #    [5] iowait: waiting for I/O to complete
    #    [6] irq: servicing interrupts
    #    [7] softirq: servicing softirqs

    words = stat_line.split
    @name = words[0]
    @total_jiffies = 0
    words.slice(1, words.length).each do |stat|
      @total_jiffies += stat.to_i
    end
    # get jiffies spent in each state
    @user = words[1].to_i
    @nice = words[2].to_i
    @system = words[3].to_i
    @idle = words[4].to_i
    @iowait = words[5].to_i
    @irq = words[6].to_i
    @softirq = words[7].to_i
  end

  def report(prev=nil)
    report = {}
    return report unless prev
    # calculate avgs since the last snapshot
    elapsed_jiffies = total_jiffies - prev.total_jiffies
    report[:idle_pct] = 100.0*(idle-prev.idle)/elapsed_jiffies
    report[:user_pct] = 100.0*(user-prev.user)/elapsed_jiffies
    report[:system_pct] = 100.0*(system-prev.system)/elapsed_jiffies
    report[:iowait_pct] = 100.0*(iowait-prev.iowait)/elapsed_jiffies
    report[:softirq_pct] = 100.0*(softirq-prev.softirq)/elapsed_jiffies
    report
  end

end