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

# generates an OS-level report on file descriptor use, based on data in
# /proc/sys/fs/file-nr

module LinuxStats::OS::FileDescriptor

  DATA_FILE = '/proc/sys/fs/file-nr'

  class Reporter
    # for description of file-nr info, see
    # https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/5/html/Tuning_and_Optimizing_Red_Hat_Enterprise_Linux_for_Oracle_9i_and_10g_Databases/chap-Oracle_9i_and_10g_Tuning_Guide-Setting_File_Handles.html

    def report(data = nil)
      # execution time: 0.1 ms  [LOW]
      file_descriptors = {}
      data = File.read(DATA_FILE) unless data
      words = data.split
      allocated = words[0].to_i
      available = words[1].to_i
      # for kernels 2.4 and below, 'used' is just os[0].  We could detect kernel version
      # from /proc/version and handle old versions, but Centos 5 and 6 all have kernels
      # 2.6 and above
      file_descriptors[:used] = allocated - available
      file_descriptors[:max] = words[2].to_i
      file_descriptors[:used_pct] = 100.0 * file_descriptors[:used] / file_descriptors[:max]
      file_descriptors
    end
  end
end
