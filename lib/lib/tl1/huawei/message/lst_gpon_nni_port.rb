# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        class LstGponNniPort < Lib::TL1::Huawei::Message::Input
          attr_reader :did, :dev, :show_option

          def initialize(did: nil, dev: nil, show_option: [])
            @did = did
            @dev = dev
            @show_option = show_option
            super(
              aid: __aid(did: did, dev: dev),
              payload: __show_option(*show_option)
            )
          end

        end
      end
    end
  end
end
