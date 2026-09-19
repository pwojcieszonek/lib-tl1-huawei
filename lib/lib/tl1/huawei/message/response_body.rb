# frozen_string_literal: true

require_relative 'response'

module Lib
  module TL1
    module Huawei
      module Message
        # Reads Huawei status, packet metadata, and tab-separated records within a TL1 frame.
        class ResponseBody
          STATUS = /(?:\A|[\r\n])[ \t]*EN[ \t]*=[ \t]*(\d+)[ \t]+ENDESC[ \t]*=[ \t]*([^\r\n]*)/
          PACKET = /(?:\A|[\r\n])[ \t]*blktag=(\d+)[ \t]*\r?\n
                    [ \t]*blkcount=(\d+)[ \t]*\r?\n
                    [ \t]*blktotal=(\d+)[ \t]*(?:\r?\n|\z)/x

          attr_reader :en, :endesc

          def initialize(text, source:)
            status = text.match(STATUS)
            raise "Can't parse #{source} text_block" unless status

            @en = status[1].to_i
            @endesc = status[2].strip
            @quoted_line = text[status.end(0)..]
          end

          def blktag
            parse_packet unless defined? @blktag
            @blktag
          end

          def blkcount
            parse_packet unless defined? @blkcount
            @blkcount
          end

          def blktotal
            parse_packet unless defined? @blktotal
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

          private

          def query
            parse_packet unless defined? @query
            @query
          end

          def parse_packet
            @blktag = @blkcount = @blktotal = @query = nil
            packet = @quoted_line.to_s.match(PACKET)
            return unless packet

            @blktag, @blkcount, @blktotal = packet.captures.map(&:to_i)
            @query = @quoted_line[packet.end(0)..]
          end

          def parse_result
            @response = []
            lines = query.to_s.lines.map(&:chomp).drop_while { |line| blank?(line) }
            @title = lines.shift&.strip
            return unless @title

            lines.shift while table_preamble?(lines.first)
            parse_table(lines)
          end

          def parse_table(lines)
            keys = lines.shift.to_s.split.map { |key| key.downcase.to_sym }
            @response = parse_records(lines, keys)
          end

          def parse_records(lines, keys)
            lines.take_while { |line| !separator?(line) }.filter_map do |line|
              next if blank?(line)

              values = line.split("\t", -1).map(&:strip)
              Response.new(keys.zip(values).to_h)
            end
          end

          def blank?(line)
            line && line.strip.empty?
          end

          def table_preamble?(line)
            line && (blank?(line) || separator?(line))
          end

          def separator?(line)
            line.strip.match?(/\A-{3,}\z/)
          end
        end
      end
    end
  end
end
