# frozen_string_literal: true

require 'lib/tl1'
require_relative 'response'
require_relative 'exception'

module Lib
  module TL1
    module Huawei
      module Message
        class Output < Lib::TL1::Message::Output
          extend Forwardable

          def_delegators :response, :[], :each, :empty?, :first, :fetch, :include?, :map, :max, :min, :pop,
                         :revers, :select, :size, :sort, :to_a, :to_h, :uniq, :as_json

          def initialize(message = nil, sid: nil, date: nil, time: nil, ctag: nil, cc: nil, text_block: nil)
            if message.nil?
              super sid: sid, date: date, time: time, ctag: ctag, cc: cc, text_block: text_block
            else
              message = Lib::TL1::Message.parse message
              unless message.instance_of? Lib::TL1::Message::Output
                raise ArgumentError, "No implicit conversion form #{message.class.name} to #{self.class.name}"
              end

              super(
                sid: message.sid,
                date: message.date,
                time: message.time,
                ctag: message.ctag,
                cc: message.cc,
                text_block: message.text_block
              )
            end
            raise Lib::TL1::Huawei::StandardError.new(self.endesc, self.error_number) unless self.error_number.to_i == 0
          end

          def to_h
            {
              sid: self.sid.to_s,
              date: self.date.to_s,
              time: self.time.to_s,
              ctag: self.ctag.to_s,
              cc: self.cc.to_s,
              en: self.en,
              endesc: self.endesc,
              blktag: self.blktag,
              blkcount: self.blkcount,
              blktotal: self.blktotal,
              title: self.title,
              response: self.response.map(&:to_h).map do |r|
                r.transform_values { |v| v.force_encoding('iso-8859-1').encode('utf-8') }
              end
            }
          end

          def en
            parse_text_block unless defined? @en
            @en
          end

          alias error_code en
          alias return_code en
          alias error_number en

          def endesc
            parse_text_block unless defined? @endesc
            @endesc
          end

          def blktag
            parse_text_block unless defined? @blktag
            @blktag
          end

          def blkcount
            parse_quoted_line unless defined? @blkcount
            @blkcount
          end

          def blktotal
            parse_quoted_line unless defined? @blktotal
            @blktotal
          end

          def title
            parse_result unless defined? @title
            @title
          end

          def response
            parse_result unless defined? @response
            @response
          end

          alias response_message response

          def self.parse(message)
            message = Lib::TL1::Message.parse message
            unless message.instance_of? Lib::TL1::Message::Output
              raise ArgumentError, "No implicit conversion of #{message.class.name} to #{self.class.name}"
            end

            new(
              sid: message.sid,
              date: message.date,
              time: message.time,
              ctag: message.ctag,
              cc: message.cc,
              text_block: message.text_block
            )
          end

          private

          def method_missing(method_name, *args)
            super if (blktotal.to_i > 1) || en.to_i.positive?
            if response.first.respond_to? method_name
              response.first.send method_name
            else
              super
            end
          end

          def respond_to_missing?(method_name, include_private = false)
            if (blktotal.to_i > 1) || en.to_i.positive?
              response.first.respond_to?( method_name) || super
            else
              super
            end
          end

          def query
            parse_quoted_line unless defined? @query
            @query
          end

          def quoted_line
            parse_text_block unless defined? @quoted_line
            @quoted_line
          end

          def parse_text_block
            raise 'text_block is nil' if text_block.nil?

            regexp = text_block.to_s.match(/EN=(\d+).*ENDESC=(.*)([^|$|;]*)/)
            if regexp
              @en = regexp[1].to_i
              @endesc = regexp[2].strip
              @quoted_line = regexp[3]
            else
              raise "Can't parse #{self.class.name} text_block"
            end
          end

          def parse_quoted_line
            raise 'text_block is nil' if text_block.nil?

            regexp = quoted_line.to_s.match(/.*blktag=(\d+).*blkcount=(\d+).*blktotal=(\d+)[\r\n]+(.*)/m)
            if regexp
              @blktag = regexp[1].to_i
              @blkcount = regexp[2].to_i
              @blktotal = regexp[3].to_i
              @query =  regexp[4]
            end
          end

          def parse_result
            i = 0
            keys = []
            @response = []
            query.to_s.each_line do |line|
              @title = line.strip if i.zero?
              keys = line.split.map { |key| key.to_s.downcase.to_sym } if i == 2
              if i > 2
                break if line.match(/^-+/)

                values = line.split(/\t/).map(&:strip)
                @response << Lib::TL1::Huawei::Message::Response.new(Hash[*keys.zip(values).flatten])
              end
              i += 1
            end
          end
        end
      end
    end
  end
end
