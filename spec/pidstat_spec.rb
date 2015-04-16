require 'pl_procstat'

PIDSTAT_VARS= {
    :cmd => 'chrome',
    :child_guest => 100,
    :child_kernel => 200,
    :child_user => 400,
    :self_guest => 200,
    :self_kernel => 300,
    :self_user => 350,
}

# 22904 (chrome) S 4424 4417 4417 0 -1 1077960768 245247
# 0 0 0 9836 4076 0 0 20 0 9
# 0 33424194 874565632 25819 18446744073709551615 1 1 0 0 0
# 0 0 4098 1073807360 18446744073709551615 0 0 17 7 0
# 0 0 0 0 0 0 0 0 0 0
# 0 0

# 10 per line to make the persnickety counting easier
PIDSTAT_STRING = "
22904 (#{PIDSTAT_VARS[:cmd]}) S 4424 4417 4417 0 -1 1077960768 245247
0 0 0 #{PIDSTAT_VARS[:self_user]} #{PIDSTAT_VARS[:self_kernel]} #{PIDSTAT_VARS[:child_user]}
#{PIDSTAT_VARS[:child_kernel]} 0 9 9836
0 33424194 874565632 25819 18446744073709551615 1 1 0 0 0
0 0 4098 1073807360 18446744073709551615 0 0 17 7 0
0 0 #{PIDSTAT_VARS[:self_guest]} #{PIDSTAT_VARS[:child_guest]} 0 0 0 0 0 0
0 0"

include Procstat::PID::Procstat

describe 'PidStatData' do

  it 'should initialize with the correct command line name' do
    p = PidStatData.new(4242, PIDSTAT_STRING)
    expect(p.cmd).to eq PIDSTAT_VARS[:cmd]
  end

  it 'should initialize with the correct user times' do
    p = PidStatData.new(4242, PIDSTAT_STRING)
    expect(p.ch_user).to eq PIDSTAT_VARS[:child_user]
    expect(p.se_user).to eq PIDSTAT_VARS[:self_user]
    expect(p.tot_user).to eq PIDSTAT_VARS[:child_user] + PIDSTAT_VARS[:self_user]
  end

  it 'should initialize with the correct kernel times' do
    p = PidStatData.new(4242, PIDSTAT_STRING)
    expect(p.ch_kernel).to eq PIDSTAT_VARS[:child_kernel]
    expect(p.se_kernel).to eq PIDSTAT_VARS[:self_kernel]
    expect(p.tot_kernel).to eq PIDSTAT_VARS[:self_kernel] + PIDSTAT_VARS[:child_kernel]
  end

  it 'should initialize with the corret guest times' do
    p = PidStatData.new(4242, PIDSTAT_STRING)
    expect(p.ch_guest).to eq PIDSTAT_VARS[:child_guest]
    expect(p.se_guest).to eq PIDSTAT_VARS[:self_guest]
    expect(p.tot_guest).to eq PIDSTAT_VARS[:child_guest] + PIDSTAT_VARS[:self_guest]
  end

end
