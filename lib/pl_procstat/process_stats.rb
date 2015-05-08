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

  # keeps a different reporter for each regex
  @@report_map = {}

  def self.report(friendly_name, regex)
    @@report_map[regex] = PidStat::Reporter.new unless @@report_map.key? regex
    ret = {}
    reporter = @@report_map[regex]
    process_pids = pids regex
    ret[friendly_name] = {}
    ret[friendly_name][:process_count] = process_pids.size
    process_pids.each do |pid|
      reporter.record pid
    end
    ret[friendly_name].merge! reporter.report
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
