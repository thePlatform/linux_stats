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

module LinuxStats::OS::Loadavg
  PROC_DIRECTORY_DEFAULT = '/proc'
  DATA_FILE = '/loadavg'

  class Reporter
    def initialize(data_directory = PROC_DIRECTORY_DEFAULT)
      set_data_paths data_directory
    end

    def set_data_paths(data_directory = nil)
      @proc_file_source = "#{data_directory}#{DATA_FILE}"
    end

    def report(data = nil)
      # execution time: 0.12 ms  [LOW]
      load_report = {}
      data = File.read(@proc_file_source) unless data
      words = data.split
      load_report[:one] = words[0].to_f
      load_report[:five] = words[1].to_f
      load_report[:fifteen] = words[2].to_f
      load_report
    end
  end
end
