require 'pl_procstat'

# generates an OS-level report on file descriptor use, based on data in
# /proc/sys/fs/file-nr

module Procstat::OS::FileDescriptor

  DATA_FILE = '/proc/sys/fs/file-nr'

  # for description of file-nr info, see
  # https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/5/html/Tuning_and_Optimizing_Red_Hat_Enterprise_Linux_for_Oracle_9i_and_10g_Databases/chap-Oracle_9i_and_10g_Tuning_Guide-Setting_File_Handles.html

  def self.report(data=nil)
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
    file_descriptors[:used_pct] = 100.0 * file_descriptors[:used]/file_descriptors[:max]
    file_descriptors
  end
end
