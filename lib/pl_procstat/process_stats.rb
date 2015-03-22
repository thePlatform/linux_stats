require 'pl_procstat'

# process_stats.rb
#
# Report generator for process-level performance statistics including
#  * CPU use
#  * Network use
#  * Disk use
#  * ...
#
# For gathering performance data on overall OS performance, see
# os_stats.rb
#

module Procstat
  def Procstat.pids(cmd)
    # execution time: 7ms  [VERY HIGH]
    pid_list = []
    Dir['/proc/[0-9]*/cmdline'].each do |p|
      pid_list.push(p.split('/')[PID_INDEX]) if File.read(p).match(cmd)
    end
    pid_list
  end
end
