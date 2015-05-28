
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

BW = {
    :bytes_rx => 1084177486625,
    :bytes_tx => 3625781977,
    :errors_rx => 0,
    :errors_tx => 3
}
ETH0_LINE = "eth0:#{BW[:bytes_rx]} 4089141436  #{BW[:errors_rx]}  0  0  0  0  0 #{BW[:bytes_tx]} 3625781977  #{BW[:errors_tx]}   0   0   0   0  0"
BW_STRING = "
Inter-|   Receive                                                |  Transmit
face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
lo:2427354553 3059524    0    0    0     0          0         0 2427354553 3059524    0    0    0     0       0          0
#{ETH0_LINE}
sit0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
"
include LinuxStats::OS

describe 'Net Stat Class' do
  # happy path
  it 'should initialize with happy data' do
    stat = NetBandwidth::Stat.new BW_STRING
    expect(stat.current_stats['eth0'].bytes_rx).to eq BW[:bytes_rx]
    expect(stat.current_stats['eth0'].bytes_tx).to eq BW[:bytes_tx]
    expect(stat.current_stats['eth0'].errors_rx).to eq BW[:errors_rx]
    expect(stat.current_stats['eth0'].errors_tx).to eq BW[:errors_tx]
  end
end

describe 'BandwidthData class' do
  # happy path
  it 'should ingest happy data' do
    bw_data = NetBandwidth::BandwidthData.new ETH0_LINE
    expect(bw_data.bytes_rx).to eq BW[:bytes_rx]
    expect(bw_data.bytes_tx).to eq BW[:bytes_tx]
    expect(bw_data.errors_rx).to eq BW[:errors_rx]
    expect(bw_data.errors_tx).to eq BW[:errors_tx]
  end
end


describe 'Module functions' do
  it 'should do a happy path report' do
    NetBandwidth.report
  end
end


