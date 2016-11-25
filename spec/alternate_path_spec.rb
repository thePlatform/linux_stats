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
include LinuxStats::Process

describe 'OS stats reporter class' do
  it 'should use alternate paths when expected' do
    use_alternate_paths = true
    os_stats = LinuxStats::OS::Reporter.new(use_alternate_paths)
    expect(os_stats.proc_directory).to eq '/hostproc'
    expect(os_stats.sys_directory).to eq '/hostsys'
  end

  it 'should use primary paths when expected' do
    os_stats = LinuxStats::OS::Reporter.new
    expect(os_stats.proc_directory).to eq '/proc'
    expect(os_stats.sys_directory).to eq '/sys'
  end
end

describe 'Process stats reporter class' do
  it 'should use alternate proc path when expected' do
    use_alternate_paths = true
    process_stats = LinuxStats::Process::Reporter.new(use_alternate_paths)
    expect(process_stats.proc_directory).to eq '/hostproc'
  end

  it 'should use primary proc path when expected' do
    process_stats = LinuxStats::Process::Reporter.new
    expect(process_stats.proc_directory).to eq '/proc'
  end
end

describe 'ProcessStats::PidStat module' do
  it 'should use passed-in proc path when expected within PidStat Reporter' do
    pid_stats = LinuxStats::Process::PidStat::Reporter.new('/testproc')
    expect(pid_stats.get_proc_directory).to eq '/testproc'
  end
end

