require 'pl_procstat'

LOAD = {
    :one => 1.11,
    :five => 5.55,
    :fifteen => 15.15,
}

include Procstat::OS

LOAD_STRING = "#{LOAD[:one]} #{LOAD[:five]} #{LOAD[:fifteen]}"

include Procstat::OS

describe 'Load Average module functions' do

  # happy path
  it 'should generate a good report' do
    report = Loadavg.report(LOAD_STRING)
    expect(report[:one]).to eq LOAD[:one]
    expect(report[:five]).to eq LOAD[:five]
    expect(report[:fifteen]).to eq LOAD[:fifteen]
  end
end
