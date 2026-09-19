# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        # Builds a LOGOUT command to end an NBI session.
        class Logout < Lib::TL1::Huawei::Message::Input
          def initialize
            super(command: 'LOGOUT')
          end
        end
      end
    end
  end
end
