require 'pl_procstat'

BW = {
    :bytes_rx => 1084177486625,
    :bytes_tx => 3625781977,
    :errors_rx => 0,
    :errors_tx => 3
}
ETH0_LINE = "eth0:#{BW[:bytes_rx]} 4089141436  #{BW[:errors_rx]}  0  0  0  0  0 #{BW[:bytes_tx]} 3625781977  #{BW[:errors_tx]}   0   0   0   0  0"
BW_STRING = "
Inter-|   Receive                                                |  Transmit
face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
lo:2427354553 3059524    0    0    0     0          0         0 2427354553 3059524    0    0    0     0       0          0
#{ETH0_LINE}
sit0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
"
include Procstat::OS

describe 'Net Stat Class' do
  # happy path
  it 'should initialize with happy data' do
    stat = NetBandwidth::Stat.new BW_STRING
    expect(stat.current_stats['eth0'].bytes_rx).to eq BW[:bytes_rx]
    expect(stat.current_stats['eth0'].bytes_tx).to eq BW[:bytes_tx]
    expect(stat.current_stats['eth0'].errors_rx).to eq BW[:errors_rx]
    expect(stat.current_stats['eth0'].errors_tx).to eq BW[:errors_tx]
  end
end

describe 'BandwidthData class' do
  # happy path
  it 'should ingest happy data' do
    bw_data = NetBandwidth::BandwidthData.new ETH0_LINE
    expect(bw_data.bytes_rx).to eq BW[:bytes_rx]
    expect(bw_data.bytes_tx).to eq BW[:bytes_tx]
    expect(bw_data.errors_rx).to eq BW[:errors_rx]
    expect(bw_data.errors_tx).to eq BW[:errors_tx]
  end
end


describe 'Module functions' do
  it 'should do a happy path report' do
    NetBandwidth.report
  end
end


