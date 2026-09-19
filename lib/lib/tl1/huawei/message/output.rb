# frozen_string_literal: true

require 'lib/tl1'
require_relative 'response_body'
require_relative 'exception'

module Lib
  module TL1
    module Huawei
      module Message
        # Combines the dependency's TL1 frame with Huawei status and result records.
        class Output < Lib::TL1::Message::Output
          extend Forwardable

          def_delegators :response, :[], :each, :empty?, :first, :fetch, :include?, :map, :max, :min, :pop,
                         :reverse, :select, :size, :sort, :to_a, :uniq, :as_json
          def_delegators :response_body, :en, :endesc, :blktag, :blkcount, :blktotal, :title, :response

          def initialize(message = nil, sid: nil, date: nil, time: nil, ctag: nil, cc: nil, text_block: nil,
                         encoding: nil)
            @source_encoding = encoding if message.nil?
            attributes = { sid: sid, date: date, time: time, ctag: ctag, cc: cc, text_block: text_block }
            attributes = parse_message(message, encoding) unless message.nil?
            super(**attributes)
            raise Lib::TL1::Huawei::StandardError.new(endesc, error_number) unless error_number.to_i.zero?
          end

          def to_h
            frame_metadata.transform_values(&:to_s).merge(
              en: en, endesc: endesc, blktag: blktag, blkcount: blkcount, blktotal: blktotal,
              title: title, response: response.map(&:to_h)
            )
          end

          alias error_code en
          alias return_code en
          alias error_number en
          alias response_message response

          def self.parse(message, encoding: nil)
            new(message, encoding: encoding)
          end

          private

          def method_missing(method_name, *, &)
            if single_record? && response.first.respond_to?(method_name)
              response.first.public_send(method_name, *, &)
            else
              super
            end
          end

          def respond_to_missing?(method_name, include_private = false)
            (single_record? && response.first.respond_to?(method_name)) || super
          end

          # Record shortcuts apply to the entire result, not one of several packets.
          def single_record?
            blktotal == 1 && response.size == 1
          end

          def decode_source(value, encoding)
            return value if encoding.nil?

            value.to_s.dup.force_encoding(encoding).encode(Encoding::UTF_8)
          end

          def parse_message(message, encoding)
            frame = Lib::TL1::Message.parse(decode_source(message, encoding))
            unless frame.instance_of?(Lib::TL1::Message::Output)
              raise ArgumentError, "No implicit conversion from #{frame.class.name} to #{self.class.name}"
            end

            frame_metadata(frame).merge(text_block: frame.text_block)
          end

          def frame_metadata(frame = self)
            { sid: frame.sid, date: frame.date, time: frame.time, ctag: frame.ctag, cc: frame.cc }
          end

          def response_body
            return @response_body if defined? @response_body

            raise 'text_block is nil' if text_block.nil?

            text = decode_source(text_block.to_s, @source_encoding)
            @response_body = ResponseBody.new(text, source: self.class.name)
          end
        end
      end
    end
  end
end
