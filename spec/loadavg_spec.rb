
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

LOAD = {
  one:  1.11,
  five: 5.55,
  fifteen: 15.15
}

include LinuxStats::OS

LOAD_STRING = "#{LOAD[:one]} #{LOAD[:five]} #{LOAD[:fifteen]}"

include LinuxStats::OS

describe 'Load Average module functions' do
  # happy path
  it 'should generate a good report' do
    reporter = Loadavg::Reporter.new
    report = reporter.report(LOAD_STRING)
    expect(report[:one]).to eq LOAD[:one]
    expect(report[:five]).to eq LOAD[:five]
    expect(report[:fifteen]).to eq LOAD[:fifteen]
  end
end
