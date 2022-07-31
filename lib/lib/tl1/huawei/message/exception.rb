module Lib
  module TL1
    module Huawei
      class StandardError < StandardError

        attr_reader :error_number

        def initialize(msg = nil, en=nil)
          super(msg)
          @error_number = en
        end

      end
    end
  end
end
