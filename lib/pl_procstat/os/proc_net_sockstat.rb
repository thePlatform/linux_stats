require 'pl_procstat'

# generates a report on the 1,5, and 15 minute load average based on
# data in the /proc/loadavg file

module Procstat::OS::NetSocket

  DATA_FILE = '/proc/net/sockstat'

  module Column
    OPEN_CONNECTIONS = 2
    TIME_WAIT_CONNECTIONS = 6
  end

  def self.report(data=nil)
    ret = {}
    data = File.read(DATA_FILE) unless data
    data.each_line do |line|
      if line =~ /^TCP/
        words = line.split()
        ret[:tcp_open_conn] = words[Column::OPEN_CONNECTIONS].to_i
        ret[:tcp_timewait_conn] = words[Column::TIME_WAIT_CONNECTIONS].to_i
      end
    end
    ret
  end

end
