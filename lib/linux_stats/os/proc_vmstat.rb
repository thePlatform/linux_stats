
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

module LinuxStats::OS::Vmstat
  module Match
    PAGE_IN = '^pgpgin'
    PAGE_OUT = '^pgpgout'
    SWAP_IN = '^pswpin'
    SWAP_OUT = '^pswpout'
  end

  DATA_FILE = '/proc/vmstat'

  class Reporter
    attr_accessor :current_stats, :current_timestamp

    def initialize(data = nil)
      set_stats data
    end

    def report(elapsed_time = nil, data = nil)
      prev_stats = @current_stats
      prev_timestamp = @current_timestamp
      set_stats data
      elapsed_time = @current_timestamp - prev_timestamp unless elapsed_time
      ret = {}
      ret[:pagein_kb_persec] =
          (@current_stats[:pagein_kb] - prev_stats[:pagein_kb]) / elapsed_time
      ret[:pageout_kb_persec] =
          (@current_stats[:pageout_kb] - prev_stats[:pageout_kb]) / elapsed_time
      ret[:swapin_kb_persec] =
          (@current_stats[:swapin_kb] - prev_stats[:swapin_kb]) / elapsed_time
      ret[:swapout_kb_persec] =
          (@current_stats[:swapout_kb] - prev_stats[:swapout_kb]) / elapsed_time
      ret
    end

    private

    # gets a snapshot of the swap and page info in /proc/vmstat
    def set_stats(vmstat_data = nil)
      vmstat_data = File.read(DATA_FILE) unless vmstat_data
      @current_timestamp = Time.now
      @current_stats = {}
      vmstat_data.each_line do |line|
        if line =~ /#{Match::PAGE_IN}/
          @current_stats[:pagein_kb] = line.split[1].to_i
          next
        end
        if line =~ /#{Match::PAGE_OUT}/
          @current_stats[:pageout_kb] = line.split[1].to_i
          next
        end
        if line =~ /#{Match::SWAP_IN}/
          @current_stats[:swapin_kb] = line.split[1].to_i
          next
        end
        if line =~ /#{Match::SWAP_OUT}/
          @current_stats[:swapout_kb] = line.split[1].to_i
        end
      end
    end
  end

end

