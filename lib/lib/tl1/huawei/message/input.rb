# frozen_string_literal: true

require 'lib/tl1'

module Lib
  module TL1
    module Huawei
      module Message
        # Serializes Huawei command parameters on top of the TL1 frame builder.
        class Input < Lib::TL1::Message::Input
          def initialize(command: nil, tid: nil, aid: nil, ctag: nil, gb: nil, payload: nil)
            command = self.class.name.split('::').last.sub(/(.)([A-Z])/, '\1-\2').upcase if command.nil?
            super
          end

          private

          def set_attributes(**attributes)
            attributes.each { |name, value| instance_variable_set("@#{name}", value) }
          end

          def __show_option(*show_option)
            show_option.empty? ? nil : show_option.map { |option| option.to_s.delete('_') }.join(' ')
          end

          def hash_to_string(**hash)
            hash.compact.map { |key, value| "#{key.to_s.delete('_').upcase}=#{value}" }.join(',')
          end
        end
      end
    end
  end
end
