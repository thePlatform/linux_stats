require 'pl_procstat'

BYTES_PER_SECTOR = 512
CENTOS_5_DISK_DATA = '  843809   117910 19447928  3456290  6750791  9315495 128530206 31415150        0  6097640 34871410'
CENTOS_6_DISK_DATA = ' 4569504   134368 414454495 84656111  1886305  6114130 64003426 32624791        0  5847939 117280149'

include Procstat::OS

describe 'Disk Stats Class' do

  it 'should parse Centos 5 os' do
    disk_stat = BlockIO::ThroughputData.new(CENTOS_5_DISK_DATA, BYTES_PER_SECTOR)
    expect(disk_stat.reads).to eq 843809
  end

  it 'should parse Centos 6 os' do
    disk_stat = BlockIO::ThroughputData.new(CENTOS_6_DISK_DATA, BYTES_PER_SECTOR)
    expect(disk_stat.reads).to eq 4569504
    expect(disk_stat.queue_time_ms).to eq 117280149
  end

end

describe 'module functions' do
  it 'should generate a happy path report' do
    BlockIO.report
  end
end