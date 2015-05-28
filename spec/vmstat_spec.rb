
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

VMSTAT_DATA = {
    :page_in => 1463025,
    :page_out => 305910309,
    :swap_in => 0,
    :swap_out => 0
}

PAGEIN_DELTA = 2
PAGEOUT_DELTA = 4
SWAPIN_DELTA = 6
SWAPOUT_DELTA = 8

VMSTAT_STRING = "
nr_anon_transparent_hugepages 42
pgpgin #{VMSTAT_DATA[:page_in]}
pgpgout #{VMSTAT_DATA[:page_out]}
pswpin #{VMSTAT_DATA[:swap_in]}
pswpout #{VMSTAT_DATA[:swap_out]}
pgalloc_dma 1
"

VMSTAT_STRING_2 = "
nr_anon_transparent_hugepages 42
pgpgin #{VMSTAT_DATA[:page_in] + PAGEIN_DELTA}
pgpgout #{VMSTAT_DATA[:page_out] + PAGEOUT_DELTA}
pswpin #{VMSTAT_DATA[:swap_in] + SWAPIN_DELTA}
pswpout #{VMSTAT_DATA[:swap_out]+ SWAPOUT_DELTA}
pgalloc_dma 1
"

include LinuxStats::OS

describe 'Vmstat' do

  it 'should build stats from /proc/vmstat os' do
    vmstat = Vmstat::Stat.new(VMSTAT_STRING)
    expect(vmstat.current_stats[:pagein_kb]).to eq VMSTAT_DATA[:page_in]
    expect(vmstat.current_stats[:pageout_kb]).to eq VMSTAT_DATA[:page_out]
    expect(vmstat.current_stats[:swapin_kb]).to eq VMSTAT_DATA[:swap_in]
    expect(vmstat.current_stats[:swapout_kb]).to eq VMSTAT_DATA[:swap_out]
  end

  it 'should generate a good report from class' do
    vmstat = Vmstat::Stat.new(VMSTAT_STRING)
    elapsed = 2.0
    report = vmstat.report(elapsed, VMSTAT_STRING_2)
    expect(report[:pagein_kb_persec]).to eq PAGEIN_DELTA/elapsed
    expect(report[:pageout_kb_persec]).to eq PAGEOUT_DELTA/elapsed
    expect(report[:swapin_kb_persec]).to eq SWAPIN_DELTA/elapsed
    expect(report[:swapout_kb_persec]).to eq SWAPOUT_DELTA/elapsed
  end

  it 'should generate a good report from module' do
    Vmstat.init(VMSTAT_STRING)
    elapsed = 2.0
    report = Vmstat.report(elapsed, VMSTAT_STRING_2)
    expect(report[:pagein_kb_persec]).to eq PAGEIN_DELTA/elapsed
    expect(report[:pageout_kb_persec]).to eq PAGEOUT_DELTA/elapsed
    expect(report[:swapin_kb_persec]).to eq SWAPIN_DELTA/elapsed
    expect(report[:swapout_kb_persec]).to eq SWAPOUT_DELTA/elapsed
  end
end
