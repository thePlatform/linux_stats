module Net
  module Column
    BYTES_RX = 0
    ERRORS_RX = 2
    BYTES_TX = 8
    ERRORS_TX = 10
  end

  class Stats

    # reads info from /proc/net/dev

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

    def to_s
      "interface: #{interface}\n" +
          "bytes_rx: #{bytes_rx}\n" +
          "bytes_tx: #{bytes_tx}\n" +
          "errors_rx: #{errors_rx}\n" +
          "errors_tx: #{errors_tx}\n"
    end
  end
end
