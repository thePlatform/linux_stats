require 'pl_procstat'

FD = {
    :allocated => 4096,
    :available => 0,
    :max => 808765
}

include Procstat::OS

FD_STRING = "#{FD[:allocated]} #{FD[:available]} #{FD[:max]}"

include Procstat::OS

describe 'File Descriptor module functions' do

  # happy path
  it 'should generate a good report' do
    report = FileDescriptor.report(FD_STRING)
    expect(report[:used]).to eq FD[:allocated] - FD[:available]
    expect(report[:max]).to eq FD[:max]
    expect(report[:used_pct]).to eq 100.0 * (FD[:allocated]-FD[:available])/FD[:max]
  end
end
