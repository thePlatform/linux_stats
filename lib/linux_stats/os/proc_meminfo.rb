
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

module LinuxStats::OS::Meminfo
  DATA_FILE = '/proc/meminfo'
  MEM_FREE = 'MemFree'
  MEM_TOTAL = 'MemTotal'
  PAGE_CACHE = 'Cached'
  SWAP_FREE = 'SwapFree'
  SWAP_TOTAL = 'SwapTotal'

  def self.report(data = nil)
    mem_report = {}
    data = File.read(DATA_FILE) unless data
    data.each_line do |line|
      if line =~ /^#{MEM_TOTAL}/
        # puts line.split[1], line.split[1].to_i
        mem_report[:mem_total_kb] = line.split[1].to_i
        next
      end
      if line =~ /^#{MEM_FREE}/
        mem_report[:mem_free_kb] = line.split[1].to_i
        next
      end
      if line =~ /^#{PAGE_CACHE}/
        mem_report[:page_cache_kb] = line.split[1].to_i
        next
      end
      if line =~ /^#{SWAP_TOTAL}/
        mem_report[:swap_total_kb] = line.split[1].to_i
        next
      end
      if line =~ /^#{SWAP_FREE}/
        mem_report[:swap_free_kb] = line.split[1].to_i
        next
      end
    end
    mem_report[:mem_used_pct] =
        100 - 100.0 * mem_report[:mem_free_kb] / mem_report[:mem_total_kb]
    mem_report[:swap_used_pct] =
        100 - 100.0 * mem_report[:swap_free_kb] / mem_report[:swap_total_kb]
    mem_report
  end
end
