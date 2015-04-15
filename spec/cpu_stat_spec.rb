require 'pl_procstat'

CENTOS_5_CPU_DATA = 'cpu1  53054583 690 12818403 154625262 985643 2316151 7762682 0'
CENTOS_6_CPU_DATA = 'cpu0 2533647 9153 430212 109730676 569761 18858 73181 0 0'
SUMMARY_CPU_DATA = 'cpu 2533647 9153 430212 109730676 569761 18858 73181 0 0'

describe 'CPU Stats Class' do

  it 'should rename "cpu" to "all"' do
    cpu_stat = Procstat::CPU::Stats.new(SUMMARY_CPU_DATA)
    expect(cpu_stat.name).to eq 'all'
  end

  it 'should parse Centos 5 os_data' do
    cpu_stat = Procstat::CPU::Stats.new(CENTOS_5_CPU_DATA)
    expect(cpu_stat.name).to eq 'cpu1'
    expect(cpu_stat.user).to eq 53054583
    expect(cpu_stat.nice).to eq 690
  end

  it 'should parse Centos 6 os_data' do
    cpu_stat = Procstat::CPU::Stats.new(CENTOS_6_CPU_DATA)
    expect(cpu_stat.name).to eq 'cpu0'
    expect(cpu_stat.user).to eq 2533647
    expect(cpu_stat.iowait).to eq 569761
  end

end
