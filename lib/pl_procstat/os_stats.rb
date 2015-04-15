require 'pl_procstat'

# os_stats.rb
#
# Report generator for OS-level statistics including
#  * CPU use
#  * Network use
#  * Disk use
#  * ...
#
# For gathering performance os on individual processes, see
# process_stats.rb
#
#
# Goals:
#   * be as fast and lightweight as possible
#   * gather all os in 10 ms or less
#   * no shelling out to existing system tools (sar, vmstat, etc.) since we
#     don't want the expense of creating a new process.
#   * provide useful statistics in the form of a sensible hash that clients
#     can inspect as desired.
#
# Goal number two seems to require us to get our os by inspecting the /proc
# filesystem.

# Other ruby tools exist for getting CPU os, etc.  Unfortunately they all
# seem to rely on shelling out to native system tools as the basis for
# retrieving their underlying os.
#
# By going directly to /proc, we have a higher level of control of the type
# of os we make available.
#
#
# Resources:
#  * http://stackoverflow.com/questions/16726779/total-cpu-usage-of-an-application-from-proc-pid-stat
#  * http://stackoverflow.com/questions/1420426/calculating-cpu-usage-of-a-process-in-linux
#  * http://stackoverflow.com/questions/3017162/how-to-get-total-cpu-usage-in-linux-c/3017438
#

module Procstat::OS

  def self.report
    os_perf_stats = {}
    os_perf_stats[:memory] = Meminfo.report
    os_perf_stats[:memory].merge! Vmstat.report
    os_perf_stats[:partition_use] = Mounts.report
    os_perf_stats[:load_avg] = Loadavg.report
    os_perf_stats[:file_descriptor] = FileDescriptor.report
    os_perf_stats[:cpu] = CPU.report
    os_perf_stats[:net] = NetBandwidth.report
    os_perf_stats[:net].merge! NetSocket.report
    os_perf_stats[:disk_io] = BlockIO.report
    os_perf_stats
  end

end