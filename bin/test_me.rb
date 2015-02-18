#!/usr/bin/env ruby

require 'pl_procstat'

# run without specifying any processes to monitor

iterations = ARGV[0].to_i
delay_sec = ARGV[1].to_i

stats = LinuxOSStats.new
stats.report
iterations.times do
  sleep(delay_sec)
  stats.report
end
