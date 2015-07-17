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

# process_stats.rb
#
# Report generator for process-level performance statistics including
#  * CPU use
#  * Network use
#  * Disk use
#  * ...
#
# For gathering performance os on overall OS performance, see
# lib/os_stats.rb
#

PID_INDEX = 2

module LinuxStats::PID
  # keeps a different reporter for each process name.  (Required for the
  # case when LinuxStats is used as a library and many reports are
  # running in the same VM)
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
    ret[friendly_name].merge! reporter.report process_pids
    ret
  end

  def self.pids(cmd)
    # execution time: 7ms  [VERY HIGH]
    pid_list = []
    Dir['/proc/[0-9]*/cmdline'].each do |p|
      begin
        pid_list.push(p.split('/')[PID_INDEX]) if File.read(p).match(cmd)
      rescue
        # ignore
      end
    end
    pid_list
  end
end
