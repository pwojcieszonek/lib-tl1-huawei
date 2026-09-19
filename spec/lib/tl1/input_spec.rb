# frozen_string_literal: true

RSpec.describe Lib::TL1::Huawei::Message::Input do
  # A synthetic command exercises the shared serializer through a builder's public API.
  let(:parameter_message) do
    Class.new(described_class) do
      def initialize(**parameters)
        super(command: 'LST-TEST', ctag: 101, aid: hash_to_string(**parameters))
      end
    end
  end

  it 'preserves false, zero and empty strings while omitting nil parameters' do
    message = parameter_message.new(ont_id: 0, enabled: false, name: '', unsupported: nil)

    expect(message.to_s).to eq('LST-TEST::ONTID=0,ENABLED=false,NAME=:101::;')
  end

  it 'normalizes underscored SHOWOPTION names in a complete device query' do
    # U2000 TL1 NBI User Guide, §15.1.3 (LST-DEV).
    message = Lib::TL1::Huawei::Message::LstDev.new(show_option: %i[DEV_IP ONU_LOCATE_INFO])
    message.ctag = 101

    expect(message.to_s).to eq('LST-DEV:::101::SHOWOPTION=DEVIP ONULOCATEINFO;')
    expect(message.show_option).to eq(%i[DEV_IP ONU_LOCATE_INFO])
  end

  it 'retains the inherited gb keyword and serializes every TL1 frame field' do
    # Generic command frame syntax: U2000 TL1 NBI User Guide, §11.2.
    message = described_class.new(
      command: 'LST-TEST', tid: 'TEST', aid: 'DID=1', ctag: 101, gb: 'TESTBLOCK', payload: 'NAME=Example'
    )

    expect(message.gb.to_s).to eq('TESTBLOCK')
    expect(message.to_s).to eq('LST-TEST:TEST:DID=1:101:TESTBLOCK:NAME=Example;')
  end
end
