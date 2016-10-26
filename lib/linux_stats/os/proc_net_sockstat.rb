# The MIT License (MIT)
#
# Copyright (c) 2015-16 Comcast Technology Solutions
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
  PROC_DIRECTORY_DEFAULT = '/proc'
  DATA_FILE = '/net/sockstat'

  module Column
    OPEN_CONNECTIONS = 2
    TIME_WAIT_CONNECTIONS = 6
  end

  class Reporter
    def initialize(data_directory = PROC_DIRECTORY_DEFAULT)
      set_data_paths data_directory
      puts "NETSOCKSTATS FILE SOURCE = #{@proc_file_source}"
    end

    def set_data_paths(data_directory = nil)
      @proc_file_source = "#{data_directory}#{DATA_FILE}"
    end

    def report(data = nil)
      ret = {}
      data = File.read(@proc_file_source) unless data
      data.each_line do |line|
        next unless line =~ /^TCP/
        words = line.split()
        ret[:tcp_open_conn] = words[Column::OPEN_CONNECTIONS].to_i
        ret[:tcp_timewait_conn] = words[Column::TIME_WAIT_CONNECTIONS].to_i
      end
      ret
    end
  end
end
