require 'pl_procstat'

module Procstat::OS::Meminfo

  DATA_FILE = '/proc/meminfo'
  MEM_FREE = 'MemFree'
  MEM_TOTAL = 'MemTotal'
  PAGE_CACHE = 'Cached'
  SWAP_FREE = 'SwapFree'
  SWAP_TOTAL = 'SwapTotal'

  def self.report(data=nil)
    mem_report = {}
    data = File.read(DATA_FILE) unless data
    data.each_line do |line|
      if line =~ /^#{MEM_TOTAL}/
        #puts line.split[1], line.split[1].to_i
        mem_report[:mem_total_kb] = line.split()[1].to_i
        next
      end
      if line =~ /^#{MEM_FREE}/
        mem_report[:mem_free_kb] = line.split()[1].to_i
        next
      end
      if line =~ /^#{PAGE_CACHE}/
        mem_report[:page_cache_kb] = line.split()[1].to_i
        next
      end
      if line =~ /^#{SWAP_TOTAL}/
        mem_report[:swap_total_kb] = line.split()[1].to_i
        next
      end
      if line =~ /^#{SWAP_FREE}/
        mem_report[:swap_free_kb] = line.split()[1].to_i
        next
      end
    end
    mem_report[:mem_used_pct] = 100 - 100.0 * mem_report[:mem_free_kb]/mem_report[:mem_total_kb]
    mem_report[:swap_used_pct] = 100 - 100.0 * mem_report[:swap_free_kb]/mem_report[:swap_total_kb]
    mem_report
  end
end
