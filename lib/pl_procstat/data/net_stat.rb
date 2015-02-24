class NetStat

  attr_reader :bytes_tx,
              :bytes_rx,
              :interface


  def initialize(stat_line)

#     Inter-|   Receive                                                |  Transmit
# face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
# eth0: 6330419547 9004526    0   75    0     0          0     26476 1055644570 7232244 1707    0    0 1030288    1766          0
# lo: 2099579347 30635436    0    0    0     0          0         0 2099579347 30635436    0    0    0     0       0          0

    words = stat_line.split
    @interface = words[0]
    @bytes_rx = words[1].to_i
    @bytes_tx = words[9].to_i

    # TODO: gather metrics on tx/rx errors
    #puts("#{interface} bytes_rx: #{bytes_rx}, tx: #{bytes_tx}")
  end
end
