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

module LinuxStats::OS

  def self.report
    os_perf_stats = {}
    os_perf_stats[:memory] = Meminfo.report
    os_perf_stats[:memory].merge! Vmstat.report
    os_perf_stats[:partition_use] = Mounts.report
    os_perf_stats[:load_avg] = Loadavg.report
    os_perf_stats[:file_descriptor] = FileDescriptor.report
    os_perf_stats[:net] = NetBandwidth.report
    os_perf_stats[:net].merge! NetSocket.report
    os_perf_stats[:disk_io] = BlockIO.report

    proc_stat_report = CPU.report
    os_perf_stats[:cpu] = proc_stat_report[:cpus]
    os_perf_stats[:os] = proc_stat_report[:os]

    os_perf_stats
  end

end