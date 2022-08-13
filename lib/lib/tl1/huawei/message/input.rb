# frozen_string_literal: true

require 'lib/tl1'

module Lib
  module TL1
    module Huawei
      module Message
        class Input < Lib::TL1::Message::Input

          def initialize(command: nil, tid: nil, aid: nil, ctag: nil, gb: nil, payload: nil)
            command = self.class.name.split('::').last.sub(/(.)([A-Z])/, '\1-\2').upcase if command.nil?
            super
          end

          private

          def __show_option(*show_option)
            show_option.empty? ? nil : show_option.map { |option| option.to_s.delete('_') }.join(' ')
          end

          def hash_to_string(**hash)
            hash.reject { |k, v| v.nil? }.map { |k, v| "#{k.to_s.delete('_').upcase}=#{v.to_s}" }.join(',')
          end

        end
      end
    end
  end
end
