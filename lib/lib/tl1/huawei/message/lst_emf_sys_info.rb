# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        # Queries management system information.
        class LstEmfSysInfo < Lib::TL1::Huawei::Message::Input
          def initialize
            super(command: 'LST-EMFSYSINFO')
          end
        end
      end
    end
  end
end
