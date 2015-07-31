
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

MEMINFO_DATA = {
  mem_free: 5,
  mem_total: 10,
  page_cache: 202,
  swap_free: 8,
  swap_total: 10
}

include LinuxStats::OS

MEMINFO_STRING = "
something_we_don't_care_about 42
#{Meminfo::MEM_FREE} #{MEMINFO_DATA[:mem_free]}
#{Meminfo::MEM_TOTAL} #{MEMINFO_DATA[:mem_total]}
#{Meminfo::PAGE_CACHE} #{MEMINFO_DATA[:page_cache]}
#{Meminfo::SWAP_FREE} #{MEMINFO_DATA[:swap_free]}
#{Meminfo::SWAP_TOTAL} #{MEMINFO_DATA[:swap_total]}
something_else_to_ignore 1
"

describe 'ProcMeminfo module functions' do
  # happy path
  it 'should generate a good report' do
    reporter = Meminfo::Reporter.new
    report = reporter.report(MEMINFO_STRING)
    expect(report[:mem_free_kb]).to eq MEMINFO_DATA[:mem_free]
    expect(report[:mem_total_kb]).to eq MEMINFO_DATA[:mem_total]
    free_mem = MEMINFO_DATA[:mem_free].to_f / MEMINFO_DATA[:mem_total].to_f
    expect(report[:mem_used_pct]).to eq 100.0 * (1 - free_mem)
  end
end
