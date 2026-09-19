# frozen_string_literal: true

RSpec.describe Lib::TL1::Huawei::Message::Output do
  # Synthetic frames: §11.3, pp. 91–92; encodings: §10, pp. 84–85.
  def fixture(name)
    File.binread(File.expand_path("../../fixtures/huawei/#{name}.tl1", __dir__))
  end

  def parse_fixture(name, **)
    described_class.parse(fixture(name), **)
  end

  it 'delegates TL1 frame parsing to the dependency, then reads the Huawei table' do
    raw = fixture('one_record')
    frame = Lib::TL1::Message.parse(raw)
    expect(frame).to be_instance_of(Lib::TL1::Message::Output)
    output = described_class.new(sid: frame.sid, date: frame.date, time: frame.time,
                                 ctag: frame.ctag, cc: frame.cc, text_block: frame.text_block)

    expect(output.to_h).to eq(
      sid: 'TEST', date: '2026-09-19', time: '12:00:00', ctag: '21', cc: 'COMPLD',
      en: 0, endesc: 'Completed with another description.', blktag: 1, blkcount: 1,
      blktotal: 1, title: 'ONT information', response: [{ ontid: '1', name: 'Office west', rxpower: '--' }]
    )
    expect(described_class.new(raw).to_h).to eq(output.to_h)
  end

  it 'recognizes success by EN regardless of the ENDESC text' do
    output = parse_fixture('one_record')
    expect(output.en).to eq(0)
    expect(output.error_number).to eq(0)
    expect(output.error_code).to eq(0)
    expect(output.return_code).to eq(0)
    expect(output.endesc).to eq('Completed with another description.')
  end

  it 'raises an error with the EN number and ENDESC description' do
    expect { parse_fixture('error') }.to raise_error(Lib::TL1::Huawei::StandardError) { |error|
      expect(error.error_number).to eq(123)
      expect(error.message).to eq('Example device error.')
    }
  end

  it 'handles an operation response without a table or packet metadata' do
    output = parse_fixture('success_no_table')
    2.times do
      expect(output.to_h).to include(
        en: 0, blktag: nil, blkcount: nil, blktotal: nil, title: nil, response: []
      )
      expect(output.response).to eq([])
      expect(output).not_to respond_to(:ont_id)
      expect { output.ont_id }.to raise_error(NoMethodError)
    end
  end

  it 'reads all metadata and to_h regardless of call order or count' do
    expected = { blktag: 2, blkcount: 1, blktotal: 3 }
    %i[blktag blkcount blktotal to_h].permutation.each do |methods|
      output = parse_fixture('one_of_many')
      2.times do
        methods.each do |method|
          value = output.public_send(method)
          if method == :to_h
            expect(value).to include(expected)
          else
            expect(value).to eq(expected.fetch(method))
          end
        end
      end
    end
  end

  it 'handles a table without records' do
    output = parse_fixture('zero_records')
    expect(output.blkcount).to eq(0)
    expect(output.blktotal).to eq(0)
    expect(output.title).to eq('ONT information')
    expect(output).to be_empty
    expect(output).not_to respond_to(:ont_id)
    expect { output.ont_id }.to raise_error(NoMethodError)
  end

  it 'delegates getters only when the entire result contains exactly one record' do
    output = parse_fixture('one_record')
    expect(output).to respond_to(:ontid, :ont_id, :rx_power)
    expect(output.ont_id).to eq('1')
    expect(output.rx_power).to eq('--')
    expect(output).not_to respond_to(:unknown_field)
    expect { output.unknown_field }.to raise_error(NoMethodError)
    expect { output.ont_id('argument') }.to raise_error(ArgumentError)
  end

  %w[many_records one_of_many].each do |name|
    it "does not delegate to the first record for #{name}" do
      output = parse_fixture(name)
      expect(output).not_to respond_to(:ont_id)
      expect { output.ont_id }.to raise_error(NoMethodError)
      expect(output.first).to respond_to(:ont_id)
      expect(output.first.ont_id).to eq(name == 'many_records' ? '1' : '2')
    end
  end

  it 'checks the current record count even after the collection changes' do
    output = parse_fixture('one_record')
    output.pop
    expect(output).not_to respond_to(:ont_id)
    expect { output.ont_id }.to raise_error(NoMethodError)
  end

  it 'preserves spaces within values, tabs as separators, and raw -- values' do
    output = parse_fixture('many_records')
    expect(output.response.map(&:to_h)).to eq(
      [
        { ontid: '1', name: 'Office west', rxpower: '--' },
        { ontid: '2', name: 'Office east', rxpower: '-20.5' }
      ]
    )
    expect(parse_fixture('placeholder').rx_power).to eq('--')
    expect(parse_fixture('empty_column').rx_power).to eq('')
  end

  it 'reads all columns of the VLAN example from §15.8.30, pp. 887–889' do
    # Adaptation of the three shown records, preserving the printed counts of 7.
    # Changes from the printed example are detailed in spec/fixtures/huawei/README.md.
    output = parse_fixture('manual_vlan_switch_pair')

    expect(output.to_h).to eq(
      sid: 'TEST', date: '2026-09-19', time: '12:00:00', ctag: '21', cc: 'COMPLD',
      en: 0, endesc: 'Succeeded.', blktag: 1, blkcount: 7, blktotal: 7,
      title: 'ont eth port vlan information OLT_TEST',
      response: [
        { did: '1', fn: '0', sn: '7', pn: '0', ontid: '1', ontporttype: 'ETH', ontportid: '1',
          vlancfgtype: 'TRANSLATION', cvlan: '1', cpri: '0', cencap: 'IPOE', svlan: '1',
          spri: '0', spripolicy: 'DSCPMAPPING' },
        { did: '1', fn: '0', sn: '7', pn: '0', ontid: '1', ontporttype: 'ETH', ontportid: '1',
          vlancfgtype: 'TRANSLATION', cvlan: '1', cpri: '1', cencap: 'IPOE', svlan: '1',
          spri: '--', spripolicy: '--' },
        { did: '1', fn: '0', sn: '7', pn: '0', ontid: '1', ontporttype: 'ETH', ontportid: '1',
          vlancfgtype: 'TRANSLATION', cvlan: '10', cpri: '1', cencap: '--', svlan: '10',
          spri: '0', spripolicy: 'SPECIFY' }
      ]
    )
    expect(output.size).to eq(3)
    expect(output).not_to respond_to(:ont_id)
    expect(output.first.ont_port_type).to eq('ETH')
  end

  it 'exposes reverse as a reversed copy of the collection' do
    output = parse_fixture('many_records')
    expect(output.reverse.map(&:ont_id)).to eq(%w[2 1])
    expect(output.map(&:ont_id)).to eq(%w[1 2])
    expect(output).not_to respond_to(:revers)
  end

  it 'identifies the invalid message type in the conversion error' do
    expect { described_class.new('SHAKEHAND:::21::;') }.to raise_error(
      ArgumentError, /No implicit conversion from Lib::TL1::Message::Input/
    )
  end

  it 'preserves the String encoding without guessing when encoding: nil' do
    raw = fixture('utf8').force_encoding(Encoding::UTF_8).freeze
    output = described_class.parse(raw)
    name = output.first.name
    2.times { expect(output.to_h[:response].first[:name]).to eq('Łódź') }
    expect(name.encoding).to eq(Encoding::UTF_8)
    expect(name).to eq('Łódź')
    expect(raw.encoding).to eq(Encoding::UTF_8)

    binary = parse_fixture('utf8')
    expect(binary.first.name.encoding).to eq(Encoding::ASCII_8BIT)
    expect(binary.first.name.bytes).to eq('Łódź'.bytes)
  end

  { 'utf8' => ['UTF-8', 'Łódź', 'Zakończono żądanie.'],
    'gbk' => %w[GBK 北京 完成],
    'iso8859_1' => ['ISO-8859-1', 'Montréal', 'Terminé.'] }.each do |name, values|
    it "decodes a copy of #{values.first} to UTF-8 without mutating the original bytes" do
      encoding, expected_name, expected_description = values
      raw = fixture(name).freeze
      original = raw.dup
      output = described_class.parse(raw, encoding: encoding)
      source_value = output.first.name.freeze
      2.times do
        expect(output.to_h[:response].first[:name]).to eq(expected_name)
        expect(output.endesc).to eq(expected_description)
        expect(source_value).to eq(expected_name)
        expect(source_value.encoding).to eq(Encoding::UTF_8)
        expect(raw).to eq(original)
        expect(raw.encoding).to eq(Encoding::ASCII_8BIT)
      end
    end
  end

  it 'also decodes text_block passed directly from the dependency parser' do
    frame = Lib::TL1::Message.parse(fixture('gbk'))
    bytes = frame.text_block.to_s.dup
    output = described_class.new(sid: frame.sid, date: frame.date, time: frame.time,
                                 ctag: frame.ctag, cc: frame.cc, text_block: frame.text_block,
                                 encoding: Encoding.find('GBK'))
    expect(output.first.name).to eq('北京')
    expect(output.to_h[:response].first[:name]).to eq('北京')
    expect(frame.text_block.to_s).to eq(bytes)
    expect(frame.text_block.to_s.encoding).to eq(Encoding::ASCII_8BIT)
  end

  it 'rejects invalid bytes instead of replacing them or guessing the encoding' do
    raw = fixture('one_record').sub('Office west', [0xFF].pack('C'))
    expect { described_class.parse(raw, encoding: 'UTF-8') }.to raise_error(ArgumentError)
    expect { described_class.parse(raw, encoding: 'GBK') }.to raise_error(Encoding::InvalidByteSequenceError)
  end
end
