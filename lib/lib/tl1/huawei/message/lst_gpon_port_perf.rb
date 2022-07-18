# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        class LstGponPortPerf < Lib::TL1::Huawei::Message::Input
          attr_reader :did, :dev, :frame_number, :slot_number, :port_number

          def initialize(did: nil, dev: nil, frame_number: nil, slot_number: nil, port_number: nil)
            @did = did
            @dev = dev
            @frame_number = frame_number
            @slot_number = slot_number
            @port_number = port_number
            super(
              aid: __aid(
                did: did, dev: dev, fn: frame_number, sn: slot_number, pn: port_number
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
