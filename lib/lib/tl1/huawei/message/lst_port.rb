# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        class LstPort < Lib::TL1::Huawei::Message::Input

          attr_reader :port_alias, :dev, :did, :onu_locate_info, :frame_number, :slot_number, :port_number,
                      :port_type, :port_status, :db_only, :show_option

          def initialize(
            port_alias: nil,
            dev: nil,
            did: nil,
            onu_locate_info: nil,
            frame_number: nil,
            slot_number: nil,
            port_number: nil,
            port_type: nil,
            port_status: nil,
            db_only: nil,
            show_option: nil
          )
            @port_alias = port_alias
            @dev = dev
            @did = did
            @onu_locate_info = onu_locate_info
            @frame_number = frame_number
            @slot_number = slot_number
            @port_number = port_number
            @port_type = port_type
            @port_status = port_status
            @db_only = db_only
            @show_option = show_option
            super(
              aid: hash_to_string(
                alias: port_alias,
                dev: dev,
                did: did,
                onu_locate_info: onu_locate_info,
                fn: frame_number,
                sn: slot_number,
                pn: port_number,
                pt: port_type,
                pstat: port_status,
                db_only: db_only
              ),
              payload: __show_option(*show_option)
            )
          end

        end
      end
    end
  end
end


