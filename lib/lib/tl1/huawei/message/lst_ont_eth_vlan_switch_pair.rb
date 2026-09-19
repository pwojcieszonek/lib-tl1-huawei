# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        # Queries VLAN switching pairs for an ONT port.
        class LstOntEthVlanSwitchPair < Lib::TL1::Huawei::Message::Input
          attr_reader :did, :dev, :frame_number, :slot_number, :port_number, :ont_id, :ont_port_type, :ont_port_id

          def initialize(
            did: nil, dev: nil, frame_number: nil, slot_number: nil, port_number: nil,
            ont_id: nil, ont_port_type: :eth, ont_port_id: nil
          )
            set_attributes(
              did:, dev:, frame_number:, slot_number:, port_number:, ont_id:, ont_port_id:, ont_port_type:
            )
            super(
              # SWTICHPAIR spelling follows the U2000 manual, §15.8.30, p. 885.
              command: 'LST-ONTETHVLANSWTICHPAIR',
              aid: hash_to_string(
                did: did, dev: dev, fn: frame_number, sn: slot_number, pn: port_number,
                ont_id: ont_id, ont_port_type: ont_port_type&.to_s&.upcase,
                ont_port_id: ont_port_id
              )
            )
          end

          alias fn frame_number
          alias pn port_number
          alias sn slot_number
        end
      end
    end
  end
end
