
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


include LinuxStats::OS

# /proc/diskstats example
DATA='
   1       0 ram0 0 0 0 0 0 0 0 0 0 0 0
   1       1 ram1 0 0 0 0 0 0 0 0 0 0 0
   1       2 ram2 0 0 0 0 0 0 0 0 0 0 0
   1       3 ram3 0 0 0 0 0 0 0 0 0 0 0
   1       4 ram4 0 0 0 0 0 0 0 0 0 0 0
   1       5 ram5 0 0 0 0 0 0 0 0 0 0 0
   1       6 ram6 0 0 0 0 0 0 0 0 0 0 0
   1       7 ram7 0 0 0 0 0 0 0 0 0 0 0
   1       8 ram8 0 0 0 0 0 0 0 0 0 0 0
   1       9 ram9 0 0 0 0 0 0 0 0 0 0 0
   1      10 ram10 0 0 0 0 0 0 0 0 0 0 0
   1      11 ram11 0 0 0 0 0 0 0 0 0 0 0
   1      12 ram12 0 0 0 0 0 0 0 0 0 0 0
   1      13 ram13 0 0 0 0 0 0 0 0 0 0 0
   1      14 ram14 0 0 0 0 0 0 0 0 0 0 0
   1      15 ram15 0 0 0 0 0 0 0 0 0 0 0
   7       0 loop0 0 0 0 0 0 0 0 0 0 0 0
   7       1 loop1 0 0 0 0 0 0 0 0 0 0 0
   7       2 loop2 0 0 0 0 0 0 0 0 0 0 0
   7       3 loop3 0 0 0 0 0 0 0 0 0 0 0
   7       4 loop4 0 0 0 0 0 0 0 0 0 0 0
   7       5 loop5 0 0 0 0 0 0 0 0 0 0 0
   7       6 loop6 0 0 0 0 0 0 0 0 0 0 0
   7       7 loop7 0 0 0 0 0 0 0 0 0 0 0
   2       0 fd0 0 0 0 0 0 0 0 0 0 0 0
   8       0 sda 63446 11570 2526342 1382104 3306981 2307768 135868280 487068 0 359368 1859196
   8       1 sda1 62990 11538 2522450 1381984 3306981 2307768 135868280 487068 0 359320 1859008
   8       2 sda2 2 0 4 0 0 0 0 0 0 0 0
   8       5 sda5 244 31 2200 76 0 0 0 0 0 76 76
   8       5 sdx 244 31 2200 76 0 0 0 0 0 76 76
  11       0 sr0 0 0 0 0 0 0 0 0 0 0 0
'

METRICS_LIST = [
  :reads_persec,
  :writes_persec,
  :bytes_read_persec,
  :bytes_written_persec,
  :avg_queue_size,
  :avg_request_bytes,
  :percent_active ]

describe 'watched disks' do

  it 'should reject block devices that have no stat file' do
    diskreporter = Block.Reporter.new
    disks = diskreporter.watched_disks DATA
    expect(disks.include? 'sda').to be true
    expect(disks.include? 'sdx').to be false
  end

  it 'should include all all metrics per block device' do
    reporter = BlockIO::Reporter.new
    report = reporter.report(1)
    _key, metrics = report.first
    expect(metrics.nil?).to be false
    METRICS_LIST.each { | metric | expect(metrics.key? metric).to be true }
  end

end
