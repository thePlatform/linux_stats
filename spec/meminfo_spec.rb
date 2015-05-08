require 'pl_procstat'

MEMINFO_DATA = {
    :mem_free => 5,
    :mem_total => 10,
    :page_cache => 202,
    :swap_free => 8,
    :swap_total => 10
}

include Procstat::OS

MEMINFO_STRING = "
something_we_don't_care_about 42
#{Meminfo::MEM_FREE} #{MEMINFO_DATA[:mem_free]}
#{Meminfo::MEM_TOTAL} #{MEMINFO_DATA[:mem_total]}
#{Meminfo::PAGE_CACHE} #{MEMINFO_DATA[:page_cache]}
#{Meminfo::SWAP_FREE} #{MEMINFO_DATA[:swap_free]}
#{Meminfo::SWAP_TOTAL} #{MEMINFO_DATA[:swap_total]}
something_else_to_ignore 1
"

describe 'ProcMeminfo module functions' do

  # happy path
  it 'should generate a good report' do
    report = Meminfo.report(MEMINFO_STRING)
    expect(report[:mem_free_kb]).to eq MEMINFO_DATA[:mem_free]
    expect(report[:mem_total_kb]).to eq MEMINFO_DATA[:mem_total]
    free_mem = MEMINFO_DATA[:mem_free].to_f/MEMINFO_DATA[:mem_total].to_f
    expect(report[:mem_used_pct]).to eq 100.0*(1-free_mem)
  end
end
