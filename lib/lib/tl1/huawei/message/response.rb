# frozen_string_literal: true

require 'ostruct'

module Lib
  module TL1
    module Huawei
      module Message
        class Response < ::OpenStruct
          private

          def method_missing(method_name, *args)
            if to_h.key?(method_name.to_s.delete('_').downcase.to_sym)
              public_send method_name.to_s.delete('_').downcase.to_sym
            else
              super
            end
          end

          def respond_to_missing?(method_name, include_private = false)
            to_h.key?(method_name.to_s.delete('_').downcase.to_sym) || super
          end
        end
      end
    end
  end
end
