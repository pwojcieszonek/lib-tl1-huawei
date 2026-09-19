# frozen_string_literal: true

# U2000 V200R016C50CP2012, §11.2–3, pp. 90–92. Synthetic frames.
# These tests also document limitations of the published lib-tl1 0.1.2 gem.
RSpec.describe 'Integration with lib-tl1' do
  let(:first_frame) do
    "\r\n\n   U2000 2026-09-19 10:20:30\r\nM  101 COMPLD\r\n   EN=0   ENDESC=OK\r\n;"
  end
  let(:second_frame) do
    "\r\n\n   U2000 2026-09-19 10:20:31\r\nM  202 COMPLD\r\n   EN=0   ENDESC=OK\r\n;"
  end

  it 'preserves two numeric CTAG values in responses passed separately' do
    first = Lib::TL1::Huawei::Message::Output.parse(first_frame)
    second = Lib::TL1::Huawei::Message::Output.parse(second_frame)

    expect(first.ctag.to_s).to eq('101')
    expect(second.ctag.to_s).to eq('202')
    expect(first.en).to eq(0)
    expect(second.en).to eq(0)
  end

  it 'allows the application to assign numeric CTAG values to requests' do
    first = Lib::TL1::Huawei::Message::Logout.new
    second = Lib::TL1::Huawei::Message::Logout.new
    first.ctag = 101
    second.ctag = 202

    expect(first.to_s).to eq('LOGOUT:::101::;')
    expect(second.to_s).to eq('LOGOUT:::202::;')
  end

  it 'exposes a dependency limitation: the constructor converts a nonnumeric CTAG to zero' do
    expect(Lib::TL1::Message::Field::CorrelationTag.new('ABC').to_s).to eq('0')
  end

  it 'exposes a dependency limitation: the parser rejects a nonnumeric CTAG' do
    expect do
      Lib::TL1::Huawei::Message::Output.parse(first_frame.sub('101', 'ABC'))
    end.to raise_error(ArgumentError, /Unknown TL1 message type/)
  end

  it 'rejects an operation response ending with > without blank lines before the terminator' do
    expect do
      Lib::TL1::Huawei::Message::Output.parse(first_frame.sub(/;\z/, '>'))
    end.to raise_error(ArgumentError, /Unknown TL1 message type/)
  end

  it 'accepts a query response with > and blank lines but does not preserve the continuation terminator' do
    path = File.expand_path('../../fixtures/huawei/one_of_many.tl1', __dir__)
    continuation = File.binread(path).sub(/;\z/, '>')
    parsed = Lib::TL1::Huawei::Message::Output.parse(continuation)

    expect(continuation).to end_with("\r\n\r\n>")
    expect(parsed.ctag.to_s).to eq('21')
    expect(parsed.blktag).to eq(2)
    expect(parsed.blkcount).to eq(1)
    expect(parsed.blktotal).to eq(3)
    expect(parsed.response.map(&:ont_id)).to eq(['2'])
    expect(parsed.to_s).to end_with("\r\n;")
  end

  it 'shows that the frame parser does not split a stream of two responses' do
    parsed = Lib::TL1::Message.parse(first_frame + second_frame)

    expect(parsed.ctag.to_s).to eq('101')
    expect(parsed.text_block.to_s).to include('M  202 COMPLD')
  end
end
