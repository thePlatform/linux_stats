
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

BYTES_PER_SECTOR = 512
CENTOS_5_DISK_DATA = '  843809   117910 19447928  3456290  6750791  9315495 128530206 31415150        0  6097640 34871410'
CENTOS_6_DISK_DATA = ' 4569504   134368 414454495 84656111  1886305  6114130 64003426 32624791        0  5847939 117280149'

include LinuxStats::OS

describe 'Disk Stats Class' do

  it 'should parse Centos 5 os' do
    disk_stat = BlockIO::ThroughputData.new(CENTOS_5_DISK_DATA, BYTES_PER_SECTOR)
    expect(disk_stat.reads).to eq 843809
  end

  it 'should parse Centos 6 os' do
    disk_stat = BlockIO::ThroughputData.new(CENTOS_6_DISK_DATA, BYTES_PER_SECTOR)
    expect(disk_stat.reads).to eq 4569504
    expect(disk_stat.queue_time_ms).to eq 117280149
  end

end

describe 'module functions' do
  it 'should generate a happy path report' do
    BlockIO.report
  end
end