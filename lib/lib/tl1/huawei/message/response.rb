# frozen_string_literal: true

require 'ostruct'

module Lib
  module TL1
    module Huawei
      module Message
        # Stores protocol columns and exposes snake_case aliases without changing their raw values.
        class Response < ::OpenStruct
          private

          def method_missing(method_name, *, &)
            column = protocol_column(method_name)
            if to_h.key?(column)
              public_send(column, *, &)
            else
              super
            end
          end

          def respond_to_missing?(method_name, include_private = false)
            to_h.key?(protocol_column(method_name)) || super
          end

          def protocol_column(method_name)
            method_name.to_s.delete('_').downcase.to_sym
          end
        end
      end
    end
  end
end
