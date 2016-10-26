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

module LinuxStats::OS
  # collection of OS-level statistic utilities

  class Reporter

    attr_reader :cpu_reporter,
                :disk_io_reporter,
                :filedescriptor_reporter,
                :loadavg_reporter,
                :mem_reporter,
                :mounts_reporter,
                :netbandwidth_reporter,
                :netsocket_reporter,
                :vmstat_reporter

    PROC_DIRECTORY_MOUNTED = '/hostproc'
    SYS_DIRECTORY_MOUNTED = '/hostsys'

    def initialize
      set_data_directories
      puts "PROC DIRECTORY = #{@proc_directory}"
      puts "SYS DIRECTORY = #{@sys_directory}"
      @cpu_reporter = CPU::Reporter.new(nil, @proc_directory)
      @disk_io_reporter = BlockIO::Reporter.new(nil, @proc_directory, @sys_directory)
      @filedescriptor_reporter = FileDescriptor::Reporter.new(@proc_directory)
      @loadavg_reporter = Loadavg::Reporter.new(@proc_directory)
      @mem_reporter = Meminfo::Reporter.new(@proc_directory)
      @mounts_reporter = Mounts::Reporter.new(@proc_directory)
      @netbandwidth_reporter = NetBandwidth::Reporter.new(nil,@proc_directory)
      @netsocket_reporter = NetSocket::Reporter.new(@proc_directory)
      @vmstat_reporter = Vmstat::Reporter.new(nil, @proc_directory)
    end

    def set_data_directories
      @proc_directory = '/proc'
      @sys_directory = '/sys'
      if Dir.exists?(PROC_DIRECTORY_MOUNTED)
        @proc_directory = PROC_DIRECTORY_MOUNTED
      end
      if Dir.exists?(SYS_DIRECTORY_MOUNTED)
        @sys_directory = SYS_DIRECTORY_MOUNTED
      end
    end

    def report
      os_stats = {}
      os_stats[:memory] = mem_reporter.report
      os_stats[:memory].merge! vmstat_reporter.report
      os_stats[:partition_use] = mounts_reporter.report
      os_stats[:load_avg] = loadavg_reporter.report
      os_stats[:file_descriptor] = filedescriptor_reporter.report
      os_stats[:net] = netbandwidth_reporter.report
      os_stats[:net].merge! netsocket_reporter.report
      os_stats[:disk_io] = disk_io_reporter.report

      proc_stat_report = cpu_reporter.report
      os_stats[:cpu] = proc_stat_report[:cpus]
      os_stats[:os] = proc_stat_report[:os]

      os_stats
    end

  end
end
