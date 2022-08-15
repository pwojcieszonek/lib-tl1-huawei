# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        class LstFrame < Lib::TL1::Huawei::Message::Input

          attr_reader :dev, :did, :frame_number, :show_option

          def initialize(dev: nil, did: nil, frame_number: nil, show_option: nil)
            @dev = dev
            @did = did
            @frame_number = frame_number
            @show_option = show_option
            super(
              aid: hash_to_string(dev: dev, did: did, fn: frame_number),
              payload: __show_option(*show_option)
            )
          end

        end
      end
    end
  end
end

