require 'pl_procstat'

# generates a report on the 1,5, and 15 minute load average based on
# data in the /proc/loadavg file

module Procstat::OS::Loadavg

  DATA_FILE = '/proc/loadavg'

  def self.report(data=nil)
    # execution time: 0.12 ms  [LOW]
    load_report = {}
    data = File.read(DATA_FILE) unless data
    words=data.split
    load_report[:one] = words[0].to_f
    load_report[:five] = words[1].to_f
    load_report[:fifteen] = words[2].to_f
    load_report
  end
end