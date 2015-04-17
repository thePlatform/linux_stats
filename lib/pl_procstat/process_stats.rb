require 'pl_procstat'

# process_stats.rb
#
# Report generator for process-level performance statistics including
#  * CPU use
#  * Network use
#  * Disk use
#  * ...
#
# For gathering performance os on overall OS performance, see
# os_stats.rb
#

PID_INDEX = 2

module Procstat::PID

  def self.report(friendly_name, regex)
    ret = {}
    process_pids = pids regex
    ret[friendly_name] = {}
    ret[friendly_name][:count] = process_pids.size
    process_pids.each do |pid|
      PidStat.init pid
      #PidStat.record pid
      ret[friendly_name].merge! PidStat.report pid
    end
    #ret.merge! PidStat.rollup
    ret
  end

  def self.pids(cmd)
    # execution time: 7ms  [VERY HIGH]
    pid_list = []
    Dir['/proc/[0-9]*/cmdline'].each do |p|
      pid_list.push(p.split('/')[PID_INDEX]) if File.read(p).match(cmd)
    end
    pid_list
  end
end
