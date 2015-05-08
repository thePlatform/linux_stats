require 'pl_procstat'

include Procstat::OS

describe 'Partition Report' do

  it 'SENSU-261 -- it should calculate correct disk used percent' do
    Mounts.report.each do |key, val|
      avail = val[:available_kb].to_f
      total = val[:total_kb].to_f
      #puts("Part: #{key},  Avail: #{avail}, tot: #{total}")
      expect(val[:used_pct]).to eq 100.0 * (1-avail/total) unless total == 0
    end
  end

end

describe 'module functions' do
  it 'should generate a happy path report' do
    Mounts.report
  end
end