require 'pl_procstat'

CENTOS_6_DATA = 'eth0: 383033999  392803    0    0    0     0          0         0 29063711  192081    0    0    0     0       0          0'
CENTOS_5_DATA = 'eth0:708601467998 7045136750    0    0    0     0          0         0 48493449385412 34323494274    0    0    0     0       0          0'

describe 'Net Stats Class' do

  it 'should parse Centos 5 data' do
    net_stat = Net::Stats.new(CENTOS_5_DATA)
    expect(net_stat.interface).to eq 'eth0'
    expect(net_stat.bytes_rx).to eq 708601467998
    expect(net_stat.bytes_tx).to eq 48493449385412
  end

  it 'should parse Centos 6 data' do
    net_stat = Net::Stats.new(CENTOS_6_DATA)
    expect(net_stat.interface).to eq 'eth0'
    expect(net_stat.bytes_rx).to eq 383033999
    expect(net_stat.bytes_tx).to eq 29063711
  end

end