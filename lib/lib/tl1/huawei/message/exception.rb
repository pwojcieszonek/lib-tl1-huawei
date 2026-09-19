# frozen_string_literal: true

module Lib
  module TL1
    module Huawei
      # Reports the Huawei EN error number alongside its ENDESC description.
      class StandardError < ::StandardError
        attr_reader :error_number

        def initialize(message = nil, error_number = nil)
          super(message)
          @error_number = error_number
        end
      end
    end
  end
end
