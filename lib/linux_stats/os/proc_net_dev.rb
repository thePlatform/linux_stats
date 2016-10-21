
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

module LinuxStats::OS::NetBandwidth
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
      words = stat_line.split(':')
      iface_data = words[1].split
      @interface = words[0].strip
      @bytes_rx = iface_data[Column::BYTES_RX].to_i
      @errors_rx = iface_data[Column::ERRORS_RX].to_i
      @bytes_tx = iface_data[Column::BYTES_TX].to_i
      @errors_tx = iface_data[Column::ERRORS_TX].to_i
    end
  end

  class Reporter
    attr_accessor :current_stats, :current_timestamp

    def initialize(data = nil)
      set_stats data
    end

    def report(elapsed_time = nil, data = nil)
      prev_stats = @current_stats
      prev_timestamp = @current_timestamp
      set_stats data
      elapsed_time = @current_timestamp - prev_timestamp unless elapsed_time
      ret = {}
      @current_stats.keys.each do |interface|
        ret[interface] = {}
        ret[interface][:tx_bytes_persec] =
            (@current_stats[interface].bytes_tx - prev_stats[interface].bytes_tx) / elapsed_time
        ret[interface][:rx_bytes_persec] =
            (@current_stats[interface].bytes_rx - prev_stats[interface].bytes_rx) / elapsed_time
        ret[interface][:errors_rx_persec] =
            (@current_stats[interface].errors_rx - prev_stats[interface].errors_rx) / elapsed_time
        ret[interface][:errors_tx_persec] =
            (@current_stats[interface].errors_tx - prev_stats[interface].errors_tx) / elapsed_time
      end
      ret
    end

    private

    def set_stats(bandwidth_data = nil)
      bandwidth_data = File.read(DATA_FILE) unless bandwidth_data
      @current_timestamp = Time.now
      @current_stats = {}
      bandwidth_data.each_line do |line|
        if line =~ /^ *eth/
          net_stat = BandwidthData.new(line)
          @current_stats[net_stat.interface] = net_stat
        end
      end
    end
  end

end
