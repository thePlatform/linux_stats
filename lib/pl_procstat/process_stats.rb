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

  def self.report(process_names)
    ret = {}
    process_names.each do |process_name|
      process_pids = pids process_name
      ret[process_name] = {}
      ret[process_name][:count] = process_pids.size
      process_pids.each do |pid|
        stat = Procstat::Stat.new(pid)
        ret[process_name][pid] = stat.report
        # TODO -- other data processors go here
      end
    end
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
