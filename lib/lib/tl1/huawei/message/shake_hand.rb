# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        # Builds the SHAKEHAND command used to check an NBI session.
        class ShakeHand < Lib::TL1::Huawei::Message::Input
          def initialize
            super(command: 'SHAKEHAND')
          end
        end
      end
    end
  end
end
