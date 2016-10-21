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

SOCKETS = {
    open: 12,
    timewait: 69
}
SOCKETS_STRING = "
sockets: used 673
TCP: inuse #{SOCKETS[:open]} orphan 0 tw #{SOCKETS[:timewait]} alloc 508 mem 30
UDP: inuse 11 mem 0
"

include LinuxStats::OS

describe 'Net Socket module function' do
  # happy path
  it 'should discover open and timewait sockets' do
    reporter = NetSocket::Reporter.new
    report = reporter.report SOCKETS_STRING
    expect(report[:tcp_open_conn]).to eq SOCKETS[:open]
    expect(report[:tcp_timewait_conn]).to eq SOCKETS[:timewait]
  end
end
