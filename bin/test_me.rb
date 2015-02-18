require 'pl_procstat'


# run without specifying any processes to monitor
stats = LinuxOSStats.new
stats.report
5.times do
  sleep(1.2)
  stats.report
end
