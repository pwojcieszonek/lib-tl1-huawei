# frozen_string_literal: true

RSpec.describe Lib::TL1::Huawei::Message do
  # Synthetic samples based on TL1 NBI User Guide V200R016C50CP2012, Issue 01.
  # Set CTAG using the public setter inherited from lib-tl1.
  describe 'independent NNI and auto-discovery queries (§15.8.3, §15.8.7)' do
    it 'loads two distinct classes through the main entry point' do
      expect(described_class::LstGponAutoFind).not_to eq(described_class::LstGponNniPort)
    end

    it 'preserves SHOWOPTION for NNI ports' do
      message = described_class::LstGponNniPort.new(did: 1, show_option: [:PSTAT])
      message.ctag = 101

      expect(message.to_s).to eq('LST-GPONNNIPORT::DID=1:101::SHOWOPTION=PSTAT;')
      expect(message.show_option).to eq([:PSTAT])
    end

    it 'omits empty SHOWOPTION in an NNI query' do
      message = described_class::LstGponNniPort.new(dev: 'OLT_TEST')
      message.ctag = 101

      expect(message.to_s).to eq('LST-GPONNNIPORT::DEV=OLT_TEST:101::;')
    end

    it 'finds ONTs by serial number' do
      message = described_class::LstGponAutoFind.new(ont_sn: '4857544300000001')
      message.ctag = 101

      expect(message.to_s).to eq('LST-GPONONTAUTOFIND::ONTSN=4857544300000001:101::;')
      expect(message.ont_sn).to eq('4857544300000001')
    end

    it 'finds ONTs on an OLT port and preserves coordinate aliases' do
      message = described_class::LstGponAutoFind.new(
        dev: 'OLT_TEST', frame_number: 0, slot_number: 8, port_number: 2
      )
      message.ctag = 101

      expect(message.to_s).to eq('LST-GPONONTAUTOFIND::DEV=OLT_TEST,FN=0,SN=8,PN=2:101::;')
      expect([message.fn, message.sn, message.pn]).to eq([0, 8, 2])
    end

    it 'allows selecting an entire OLT by DID without port coordinates' do
      message = described_class::LstGponAutoFind.new(did: 1)
      message.ctag = 101

      expect(message.to_s).to eq('LST-GPONONTAUTOFIND::DID=1:101::;')
    end
  end

  it 'sends SHAKEHAND without a hyphen (§13.1.7, pp. 106–107)' do
    message = described_class::ShakeHand.new
    message.ctag = 101

    expect(message.to_s).to eq('SHAKEHAND:::101::;')
  end

  describe 'VLAN command based on §15.8.30, pp. 885–888' do
    it 'sends the documented SWTICHPAIR and default ETH type while preserving the Ruby API' do
      message = described_class::LstOntEthVlanSwitchPair.new(
        did: 1, frame_number: 0, slot_number: 7, port_number: 0, ont_id: 1, ont_port_id: 1
      )
      message.ctag = 101

      expect(message.to_s).to eq(
        'LST-ONTETHVLANSWTICHPAIR::DID=1,FN=0,SN=7,PN=0,ONTID=1,ONTPORTTYPE=ETH,ONTPORTID=1:101::;'
      )
      expect(message.ont_port_type).to eq(:eth)
      expect([message.fn, message.sn, message.pn]).to eq([0, 7, 0])
    end

    it 'supports DEV and omission of optional ONTPORTTYPE as in the manual example' do
      message = described_class::LstOntEthVlanSwitchPair.new(
        dev: 'OLT_TEST', frame_number: 0, slot_number: 7, port_number: 0,
        ont_id: 1, ont_port_type: nil, ont_port_id: 1
      )
      message.ctag = 101

      expect(message.to_s).to eq(
        'LST-ONTETHVLANSWTICHPAIR::DEV=OLT_TEST,FN=0,SN=7,PN=0,ONTID=1,ONTPORTID=1:101::;'
      )
      expect(message.ont_port_type).to be_nil
    end

    [[:moca, 'MOCA'], %w[IPHOST IPHOST], [:eth, 'ETH'], %w[vdsl2 VDSL2]].each do |type, wire_type|
      it "serializes the documented port type #{wire_type}" do
        message = described_class::LstOntEthVlanSwitchPair.new(
          did: 1, frame_number: 0, slot_number: 7, port_number: 0,
          ont_id: 1, ont_port_type: type, ont_port_id: 1
        )
        message.ctag = 101

        expect(message.to_s).to eq(
          "LST-ONTETHVLANSWTICHPAIR::DID=1,FN=0,SN=7,PN=0,ONTID=1,ONTPORTTYPE=#{wire_type},ONTPORTID=1:101::;"
        )
        expect(message.ont_port_type).to eq(type)
      end
    end
  end

  describe 'PSTN payload (§15.8.29, pp. 876 and 879)' do
    [
      [true, [], 'OFFQRYFLAG=Enable'],
      [false, [], 'OFFQRYFLAG=Disable'],
      [true, [:VAGID], 'OFFQRYFLAG=Enable,SHOWOPTION=VAGID'],
      [false, %i[VAGID VAG_NAME DIALMODE], 'OFFQRYFLAG=Disable,SHOWOPTION=VAGID VAGNAME DIALMODE']
    ].each do |flag, options, expected_payload|
      it "serializes off_query_flag=#{flag} and show_option=#{options.inspect}" do
        message = described_class::LstOntVoipPstnUser.new(
          did: 1, frame_number: 0, slot_number: 8, port_number: 2, ont_id: 3,
          ont_port_id: 1, off_query_flag: flag, show_option: options
        )
        message.ctag = 101

        expect(message.to_s).to eq(
          "LST-ONTVOIPPSTNUSER::DID=1,FN=0,SN=8,PN=2,ONTID=3,ONTPORTID=1:101::#{expected_payload};"
        )
        first_payload = message.payload
        expect(first_payload.to_s).to eq(expected_payload)
        expect(message.payload).to equal(first_payload)
        expect(message.payload.to_s).to eq(expected_payload)
        expect(message.off_query_flag).to eq(flag ? 'Enable' : 'Disable')
        expect(message.show_option).to eq(options)
      end
    end

    it 'preserves support for a string flag and addressing by ONTKEY' do
      message = described_class::LstOntVoipPstnUser.new(
        dev: 'OLT_TEST', ont_key: 'ONT_TEST', off_query_flag: 'enable'
      )
      message.ctag = 101

      expect(message.to_s).to eq('LST-ONTVOIPPSTNUSER::DEV=OLT_TEST,ONTKEY=ONT_TEST:101::OFFQRYFLAG=Enable;')
    end
  end

  describe 'device getters (§15.1.3, p. 259)' do
    it 'exposes dev_type and both spellings of the SHOWOPTION getter' do
      message = described_class::LstDev.new(dev_type: 34, show_option: [:DEVIP])
      message.ctag = 101

      expect(message.dev_type).to eq(34)
      expect(message.show_option).to eq([:DEVIP])
      expect(message.showoption).to equal(message.show_option)
      expect(message.to_s).to eq('LST-DEV::DT=34:101::SHOWOPTION=DEVIP;')
    end

    it 'preserves default values and omits unspecified fields' do
      message = described_class::LstDev.new
      message.ctag = 101

      expect(message.dev_type).to be_nil
      expect(message.showoption).to eq([])
      expect(message.show_option).to eq([])
      expect(message.to_s).to eq('LST-DEV:::101::;')
    end
  end

  # Command names and AID suffixes are explicit, not generated by a builder helper.
  [
    [described_class::LstOntDetail, 'LST-ONTDETAIL', '15.8.5, p. 765', {}, ''],
    [described_class::LstOntIpInfo, 'LST-ONTIPINFO', '15.8.6, p. 773', {}, ''],
    [described_class::LstOntRunInfo, 'LST-ONTRUNINFO', '15.8.8, p. 781', {}, ''],
    [described_class::LstOntPort, 'LST-ONTPORT', '15.8.9, p. 787',
     { ont_port_type: 'ETH', ont_port_id: 1 }, ',ONTPORTTYPE=ETH,ONTPORTID=1'],
    [described_class::LstOntPortDetail, 'LST-ONTPORTDETAIL', '15.8.10, p. 792',
     { ont_port_type: 'ETH', ont_port_id: 1 }, ',ONTPORTTYPE=ETH,ONTPORTID=1'],
    [described_class::LstOntPotsState, 'LST-ONTPOTSSTATE', '15.8.12, p. 801', {}, ''],
    [described_class::LstOntEthPortPerf, 'LST-ONTETHPORTPERF', '15.8.17, p. 825',
     { ont_port_type: 'ETH', ont_port_id: 1 }, ',ONTPORTTYPE=ETH,ONTPORTID=1'],
    [described_class::LstOntQueueShaping, 'LST-ONTQUEUESHAPING', '15.8.31, p. 889',
     { queue_id: 1 }, ',QUEUEID=1']
  ].each do |builder, command, source, extra_arguments, aid_suffix|
    describe "#{builder.name} (§#{source})" do
      it 'maps ont_name to NAME and preserves the Ruby getter' do
        message = builder.new(**extra_arguments, dev: 'OLT_TEST', ont_name: 'ONT_TEST')
        message.ctag = 101

        expect(message.ont_name).to eq('ONT_TEST')
        expect(message.to_s).to eq("#{command}::DEV=OLT_TEST,NAME=ONT_TEST#{aid_suffix}:101::;")
      end

      it 'maps a standalone ont_alias to ALIAS and preserves the Ruby getter' do
        message = builder.new(**extra_arguments, ont_alias: 'ALIAS_TEST')
        message.ctag = 101

        expect(message.ont_alias).to eq('ALIAS_TEST')
        expect(message.to_s).to eq("#{command}::ALIAS=ALIAS_TEST#{aid_suffix}:101::;")
      end

      it 'preserves addressing by DID and ONT coordinates without empty NAME and ALIAS fields' do
        message = builder.new(**extra_arguments, did: 1, frame_number: 0, slot_number: 8, port_number: 2, ont_id: 3)
        message.ctag = 101

        expect(message.to_s).to eq("#{command}::DID=1,FN=0,SN=8,PN=2,ONTID=3#{aid_suffix}:101::;")
      end
    end
  end

  describe 'ONT password on the wire (§15.8.4, p. 755 and §15.8.18, p. 831)' do
    it 'maps ont_pwd to PWD in LstOnt' do
      message = described_class::LstOnt.new(ont_pwd: 'TEST1234', did: 1)
      message.ctag = 101

      expect(message.ont_pwd).to eq('TEST1234')
      expect(message.to_s).to eq('LST-ONT::PWD=TEST1234,DID=1:101::;')
    end

    it 'omits nil instead of sending an empty password in LstOnt' do
      message = described_class::LstOnt.new(
        did: 1, frame_number: 0, slot_number: 8, port_number: 2, ont_id: 3, ont_pwd: nil
      )
      message.ctag = 101

      expect(message.to_s).to eq('LST-ONT::DID=1,FN=0,SN=8,PN=2,ONTID=3:101::;')
    end

    it 'maps ont_pwd to PWD in LstOntDbaProf' do
      message = described_class::LstOntDbaProf.new(dev: 'OLT_TEST', ont_pwd: 'TEST1234')
      message.ctag = 101

      expect(message.ont_pwd).to eq('TEST1234')
      expect(message.to_s).to eq('LST-ONTDBAPROF::DEV=OLT_TEST,PWD=TEST1234:101::;')
    end

    it 'omits nil instead of sending an empty password in LstOntDbaProf' do
      message = described_class::LstOntDbaProf.new(
        dev: 'OLT_TEST', frame_number: 0, slot_number: 8, port_number: 2, ont_id: 3, ont_pwd: nil
      )
      message.ctag = 101

      expect(message.to_s).to eq('LST-ONTDBAPROF::DEV=OLT_TEST,FN=0,SN=8,PN=2,ONTID=3:101::;')
    end
  end
end
