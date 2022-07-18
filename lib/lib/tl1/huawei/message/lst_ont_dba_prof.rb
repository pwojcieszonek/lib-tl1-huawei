# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        class LstOntDbaProf < Lib::TL1::Huawei::Message::Input
          attr_reader :did, :dev, :frame_number, :slot_number, :port_number, :ont_id, :ont_pwd, :show_option

          def initialize(
            did: nil, dev: nil, frame_number: nil, slot_number: nil, port_number: nil,
            ont_id: nil, ont_pwd: nil, show_option: []
          )
            @did = did
            @dev = dev
            @frame_number = frame_number
            @slot_number = slot_number
            @port_number = port_number
            @ont_id = ont_id
            @ont_pwd = ont_pwd
            @show_option = show_option
            super(
              aid: __aid(
                did: did, dev: dev, fn: frame_number, sn: slot_number,pn: port_number, ont_id: ont_id, ont_pwd: ont_pwd
              ),
              payload: __show_option(*show_option)
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
