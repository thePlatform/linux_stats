require 'pl_procstat'

module Procstat

  module Match
    PAGE_IN = '^pgpgin'
    PAGE_OUT = '^pgpgout'
    SWAP_IN = '^pswpin'
    SWAP_OUT = '^pswpout'
  end


  # I think I like this pattern better than the one in cpu_stat.rb or disk_io_stat.rb.
  # It reduces object creation and pulls boilerplate code out of os_stats.rb
  class Vmstat
    attr_accessor :current_stats, :current_timestamp

    def initialize(data=nil)
      set_stats data
    end

    def report(elapsed_time=nil, data=nil)
      prev_stats = @current_stats
      prev_timestamp = @current_timestamp
      set_stats data
      elapsed_time = @current_timestamp - prev_timestamp unless elapsed_time
      ret = {}
      ret[:pagein_kb_persec] = (@current_stats[:pagein_kb]-prev_stats[:pagein_kb])/elapsed_time
      ret[:pageout_kb_persec] = (@current_stats[:pageout_kb]-prev_stats[:pageout_kb])/elapsed_time
      ret[:swapin_kb_persec] = (@current_stats[:swapin_kb]-prev_stats[:swapin_kb])/elapsed_time
      ret[:swapout_kb_persec] = (@current_stats[:swapout_kb]-prev_stats[:swapout_kb])/elapsed_time
      ret
    end

    private

    # gets a snapshot of the swap and page info in /proc/vmstat
    def set_stats(vmstat_data=nil)
      vmstat_data = File.read(Procstat::DataFile::VMSTAT) unless vmstat_data
      @current_timestamp = Time.now()
      @current_stats = {}
      vmstat_data.each_line do |line|
        if line =~ /#{Match::PAGE_IN}/
          @current_stats[:pagein_kb] = line.split[1].to_i
        end
        if line =~ /#{Match::PAGE_OUT}/
          @current_stats[:pageout_kb] = line.split[1].to_i
        end
        if line =~ /#{Match::SWAP_IN}/
          @current_stats[:swapin_kb] = line.split[1].to_i
        end
        if line =~ /#{Match::SWAP_OUT}/
          @current_stats[:swapout_kb] = line.split[1].to_i
        end
      end
      @current_stats
    end

  end

end