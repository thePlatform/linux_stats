require 'pl_procstat'

SOCKETS={
    :open => 12,
    :timewait => 69
}
SOCKETS_STRING = "
sockets: used 673
TCP: inuse #{SOCKETS[:open]} orphan 0 tw #{SOCKETS[:timewait]} alloc 508 mem 30
UDP: inuse 11 mem 0
"

include Procstat::OS

describe 'Net Socket module function' do

  # happy path
  it 'should discover open and timewait sockets' do
    report = NetSocket.report SOCKETS_STRING
    expect(report[:tcp_open_conn]).to eq SOCKETS[:open]
    expect(report[:tcp_timewait_conn]).to eq SOCKETS[:timewait]
  end
end

