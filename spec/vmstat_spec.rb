require 'pl_procstat'

VMSTAT_DATA = {
    :page_in => 1463025,
    :page_out => 305910309,
    :swap_in => 0,
    :swap_out => 0
}

PAGEIN_DELTA = 2
PAGEOUT_DELTA = 4
SWAPIN_DELTA = 6
SWAPOUT_DELTA = 8

VMSTAT_STRING = "
nr_anon_transparent_hugepages 42
pgpgin #{VMSTAT_DATA[:page_in]}
pgpgout #{VMSTAT_DATA[:page_out]}
pswpin #{VMSTAT_DATA[:swap_in]}
pswpout #{VMSTAT_DATA[:swap_out]}
pgalloc_dma 1
"

VMSTAT_STRING_2 = "
nr_anon_transparent_hugepages 42
pgpgin #{VMSTAT_DATA[:page_in] + PAGEIN_DELTA}
pgpgout #{VMSTAT_DATA[:page_out] + PAGEOUT_DELTA}
pswpin #{VMSTAT_DATA[:swap_in] + SWAPIN_DELTA}
pswpout #{VMSTAT_DATA[:swap_out]+ SWAPOUT_DELTA}
pgalloc_dma 1
"

describe 'Vmstat' do

  it 'should build stats from /proc/vmstat data' do
    vmstat = Procstat::Vmstat.new(VMSTAT_STRING)
    expect(vmstat.current_stats[:pagein_kb]).to eq VMSTAT_DATA[:one][:page_in]
    # expect(stats[:pageout_kb]).to eq VMSTAT_DATA[:one][:page_out]
    # expect(stats[:swapin_kb]).to eq VMSTAT_DATA[:one][:swap_in]
    # expect(stats[:swapout_kb]).to eq VMSTAT_DATA[:one][:swap_out]
  end

  it 'should generate a good report' do
    vmstat = Procstat::Vmstat.new()
    vmstat.set_stats(VMSTAT_STRING)
    vmstat.set_stats(VMSTAT_STRING_2)
    elapsed = 2.0
    report = vmstat.report(elapsed)
    expect(report[:pagein_kb_persec]).to eq PAGEIN_DELTA/elapsed
  end

end
