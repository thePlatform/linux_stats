require 'pl_procstat'

module Procstat::OS::NetBandwidth

  DATA_FILE = '/proc/net/dev'

  module Column
    BYTES_RX = 0
    ERRORS_RX = 2
    BYTES_TX = 8
    ERRORS_TX = 10
  end

  class BandwidthData

    # converts info from /proc/net/dev into an object

    attr_reader :bytes_tx,
                :bytes_rx,
                :errors_rx,
                :errors_tx,
                :interface

    def initialize(stat_line)
      words=stat_line.split(':')
      iface_data = words[1].split
      @interface = words[0].strip
      @bytes_rx = iface_data[Column::BYTES_RX].to_i
      @errors_rx = iface_data[Column::ERRORS_RX].to_i
      @bytes_tx = iface_data[Column::BYTES_TX].to_i
      @errors_tx = iface_data[Column::ERRORS_TX].to_i
    end

  end


  class Stat
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
      @current_stats.keys.each do |interface|
        ret[interface] = {}
        ret[interface][:tx_bytes_persec] =
            (@current_stats[interface].bytes_tx - prev_stats[interface].bytes_tx)/elapsed_time
        ret[interface][:rx_bytes_persec] =
            (@current_stats[interface].bytes_rx - prev_stats[interface].bytes_rx)/elapsed_time
        ret[interface][:errors_rx_persec] =
            (@current_stats[interface].errors_rx - prev_stats[interface].errors_rx)/elapsed_time
        ret[interface][:errors_tx_persec] =
            (@current_stats[interface].errors_tx - prev_stats[interface].errors_tx)/elapsed_time
      end
      ret
    end

    private

    def set_stats(bandwidth_data=nil)
      bandwidth_data = File.read(DATA_FILE) unless bandwidth_data
      @current_timestamp = Time.now()
      @current_stats = {}
      bandwidth_data.each_line do |line|
        if line =~ /^ *eth/
          net_stat = BandwidthData.new(line)
          @current_stats[net_stat.interface] = net_stat
        end
      end
    end
  end

  def self.init(data=nil)
    @@stat = Procstat::OS::NetBandwidth::Stat.new(data)
  end

  def self.report(elapsed_time=nil, data=nil)
    @@stat.report(elapsed_time, data)
  end
end

Procstat::OS::NetBandwidth.init