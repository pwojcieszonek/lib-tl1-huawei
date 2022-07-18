# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        class LstOntVoipPstnUser < Lib::TL1::Huawei::Message::Input
          attr_reader :did, :dev, :frame_number, :slot_number, :port_number, :ont_id, :ont_key, :ont_port_id,
                      :off_query_flag, :show_option

          def initialize(
            did: nil, dev: nil, frame_number: nil, slot_number: nil, port_number: nil, ont_id: nil,
            ont_key: nil, ont_port_id: nil, off_query_flag: false, show_option: []
          )
            @did = did
            @dev = dev
            @frame_number = frame_number
            @slot_number = slot_number
            @port_number = port_number
            @ont_id = ont_id
            @ont_key = ont_key
            @ont_port_id = ont_port_id
            self.off_query_flag = off_query_flag
            @show_option = show_option
            super(
              aid: __aid(
                did: did, dev: dev, fn: frame_number, sn: slot_number, pn: port_number,
                ont_id: ont_id, ont_key: ont_key, ont_port_id: ont_port_id
              )
            )
          end

          def payload
            return @payload if @payload

            tmp_payload = off_query_flag
            tmp_payload += ',' if !tmp_payload.empty? && !show_option.empty?
            tmp_payload += show_option
            self.payload = tmp_payload
            @payload
          end

          alias fn frame_number
          alias pn port_number
          alias sn slot_number

          private

          def off_query_flag=(off_query_flag)
            @off_query_flag = if off_query_flag.is_a?(TrueClass) || off_query_flag.is_a?(FalseClass)
                                off_query_flag ? 'Enable' : 'Disable'
                              else
                                off_query_flag.to_s.capitalize
                              end
          end
        end
      end
    end
  end
end
