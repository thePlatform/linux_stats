
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

# generates a report on the 1,5, and 15 minute load average based on
# data in the /proc/loadavg file

module LinuxStats::OS::NetSocket

  DATA_FILE = '/proc/net/sockstat'

  module Column
    OPEN_CONNECTIONS = 2
    TIME_WAIT_CONNECTIONS = 6
  end

  def self.report(data=nil)
    ret = {}
    data = File.read(DATA_FILE) unless data
    data.each_line do |line|
      if line =~ /^TCP/
        words = line.split()
        ret[:tcp_open_conn] = words[Column::OPEN_CONNECTIONS].to_i
        ret[:tcp_timewait_conn] = words[Column::TIME_WAIT_CONNECTIONS].to_i
      end
    end
    ret
  end

end