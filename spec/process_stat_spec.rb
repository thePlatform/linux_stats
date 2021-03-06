
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

PIDSTAT_VARS = {
  cmd: 'chrome',
  child_guest: 100,
  child_kernel: 200,
  child_user: 400,
  rss: 101_010,
  self_guest: 200,
  self_kernel: 300,
  self_user: 350,
  start_time: Time.now.to_i - 100,
  threads: 10,
  vmem: 20_202_020
}

# 5 per line to make the persnickety counting easier
PIDSTAT_STRING = "
22904 (#{PIDSTAT_VARS[:cmd]}) S 4424 4417
4417 0 -1 1077960768 245247
0 0 0 #{PIDSTAT_VARS[:self_user]} #{PIDSTAT_VARS[:self_kernel]}
#{PIDSTAT_VARS[:child_user]} #{PIDSTAT_VARS[:child_kernel]} 0 9 #{PIDSTAT_VARS[:threads]}
0 #{PIDSTAT_VARS[:start_time]} #{PIDSTAT_VARS[:vmem]} #{PIDSTAT_VARS[:rss]} 18446744073709551615
1 1 0 0 0
0 0 4098 1073807360 18446744073709551615
0 0 17 7 0
0 0 #{PIDSTAT_VARS[:self_guest]} #{PIDSTAT_VARS[:child_guest]} 0
0 0 0 0 0
0 0"

include LinuxStats::Process::PidStat

describe 'PidStatData' do
  it 'should initialize with the correct command line name' do
    p = PidStatData.new(4242, PIDSTAT_STRING)
    expect(p.cmd).to eq PIDSTAT_VARS[:cmd]
  end

  it 'should initialize with the correct user times' do
    p = PidStatData.new(4242, PIDSTAT_STRING)
    expect(p.ch_user).to eq PIDSTAT_VARS[:child_user]
    expect(p.se_user).to eq PIDSTAT_VARS[:self_user]
    expect(p.tot_user).to eq PIDSTAT_VARS[:child_user] + PIDSTAT_VARS[:self_user]
  end

  it 'should initialize with the correct kernel times' do
    p = PidStatData.new(4242, PIDSTAT_STRING)
    expect(p.ch_kernel).to eq PIDSTAT_VARS[:child_kernel]
    expect(p.se_kernel).to eq PIDSTAT_VARS[:self_kernel]
    expect(p.tot_kernel).to eq PIDSTAT_VARS[:self_kernel] + PIDSTAT_VARS[:child_kernel]
  end

  it 'should initialize with the corret guest times' do
    p = PidStatData.new(4242, PIDSTAT_STRING)
    expect(p.ch_guest).to eq PIDSTAT_VARS[:child_guest]
    expect(p.se_guest).to eq PIDSTAT_VARS[:self_guest]
    expect(p.tot_guest).to eq PIDSTAT_VARS[:child_guest] + PIDSTAT_VARS[:self_guest]
  end

  it 'should initialize with the correct memory info' do
    p = PidStatData.new(4242, PIDSTAT_STRING)
    expect(p.resident_set_pages).to eq PIDSTAT_VARS[:rss]
    expect(p.virtual_mem_bytes).to eq PIDSTAT_VARS[:vmem]
  end

  it 'should intitialize with thread info' do
    p = PidStatData.new(4242, PIDSTAT_STRING)
    expect(p.threads).to eq PIDSTAT_VARS[:threads]
  end

  it 'should intitialize with start time info' do
    p = PidStatData.new(4242, PIDSTAT_STRING)
    expect(p.start_time).to eq PIDSTAT_VARS[:start_time]
  end
end
