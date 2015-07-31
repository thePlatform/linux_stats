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

CENTOS_5_CPU_DATA = 'cpu1  53054583 690 12818403 154625262 985643 2316151 7762682 0'
CENTOS_6_CPU_DATA = 'cpu0 2533647 9153 430212 109730676 569761 18858 73181 0 0'
SUMMARY_CPU_DATA = 'cpu 2533647 9153 430212 109730676 569761 18858 73181 0 0'

include LinuxStats::OS::CPU

describe 'CPUData container class' do
  it 'should rename "cpu" to "all"' do
    cpu_stat = CPUData.new(SUMMARY_CPU_DATA)
    expect(cpu_stat.name).to eq 'all'
  end

  it 'should parse Centos 5 os' do
    cpu_stat = CPUData.new(CENTOS_5_CPU_DATA)
    expect(cpu_stat.name).to eq 'cpu1'
    expect(cpu_stat.user).to eq 53_054_583
    expect(cpu_stat.nice).to eq 690
  end

  it 'should parse Centos 6 os' do
    cpu_stat = CPUData.new(CENTOS_6_CPU_DATA)
    expect(cpu_stat.name).to eq 'cpu0'
    expect(cpu_stat.user).to eq 2_533_647
    expect(cpu_stat.iowait).to eq 569_761
  end
end
