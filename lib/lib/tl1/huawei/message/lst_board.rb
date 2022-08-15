# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        class LstBoard < Lib::TL1::Huawei::Message::Input

          attr_reader :dev, :did, :onu_locate_info, :frame_number, :slot_number, :board_type, :show_option

          def initialize(
            dev: nil,
            did: nil,
            onu_locate_info: nil,
            frame_number: nil,
            slot_number: nil,
            board_type: nil,
            show_option: nil
          )
            @dev = dev
            @did = did
            @frame_number = frame_number
            @onu_locate_info = onu_locate_info
            @slot_number = slot_number
            @board_type = board_type
            @show_option = show_option

            super(
              aid: hash_to_string(
                dev: dev,
                did: did,
                onu_locate_info: onu_locate_info,
                fn: frame_number,
                sn: slot_number,
                bt: board_type
              ),
              payload: __show_option(*show_option)
            )
          end

        end
      end
    end
  end
end

