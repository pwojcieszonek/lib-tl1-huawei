# frozen_string_literal: true

require_relative 'input'
module Lib
  module TL1
    module Huawei
      module Message
        class LstOntDetail < Lib::TL1::Huawei::Message::Input
          attr_reader :did, :dev, :frame_number, :slot_number, :port_number, :ont_id,
                      :ont_name, :ont_alias, :show_option

          def initialize(
            did: nil, dev: nil, frame_number: nil, slot_number: nil, port_number: nil, ont_id: nil,
            ont_name: nil, ont_alias: nil, show_option: []
          )
            @did = did
            @dev = dev
            @frame_number = frame_number
            @slot_number = slot_number
            @port_number = port_number
            @ont_id = ont_id
            @ont_name = ont_name
            @ont_alias = ont_alias
            @show_option = show_option
            super(
              aid: __aid(
                did: did, dev: dev, fn: frame_number, sn: slot_number, pn: port_number,
                ont_id: ont_id, ont_name: ont_name, ont_alias: ont_alias
              ),
              payload: __show_option(*show_option)
            )
          end
        end
      end
    end
  end
end
