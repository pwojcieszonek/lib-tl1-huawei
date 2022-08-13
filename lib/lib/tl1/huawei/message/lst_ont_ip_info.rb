# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        class LstOntIpInfo < Lib::TL1::Huawei::Message::Input

          attr_reader :did, :dev, :frame_number, :slot_number, :port_number, :ont_id, :ont_name, :ont_alias

          def initialize(
            did: nil, dev: nil, frame_number: nil, slot_number: nil, port_number: nil,
            ont_id: nil, ont_name: nil, ont_alias: nil
          )
            @did = did
            @dev = dev
            @frame_number = frame_number
            @slot_number = slot_number
            @port_number = port_number
            @ont_id = ont_id
            @ont_name = ont_name
            @ont_alias = ont_alias
            super(
              aid: hash_to_string(
                did: did, dev: dev, fn: frame_number, sn: slot_number, pn: port_number, ont_id: ont_id,
                ont_name: ont_name, ont_alias: ont_alias
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
