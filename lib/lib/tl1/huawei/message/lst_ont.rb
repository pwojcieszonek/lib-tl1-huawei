# frozen_string_literal: true

require_relative 'input'
module Lib
  module TL1
    module Huawei
      module Message
        class LstOnt < Lib::TL1::Huawei::Message::Input

          attr_reader :onu_name, :ont_sn, :ont_pwd, :did, :dev, :frame_number, :slot_number,
                      :port_number, :ont_id, :run_state, :onu_did, :onu_dev, :show_option

          def initialize(
            onu_name: nil, ont_sn: nil, ont_pwd: nil, did: nil, dev: nil, frame_number: nil,
            slot_number: nil, port_number: nil, ont_id: nil, run_stat: nil, onu_did: nil, onu_dev: nil, show_option: []
          )
            @onu_name = onu_name
            @ont_sn = ont_sn
            @ont_pwd = ont_pwd
            @did = did
            @dev = dev
            @frame_number = frame_number
            @slot_number = slot_number
            @port_number = port_number
            @ont_id = ont_id
            @run_state = run_stat
            @onu_did = onu_did
            @onu_dev = onu_dev
            @show_option = show_option
            super(
              aid: hash_to_string(
                name: onu_name, ont_sn: ont_sn, ont_pwd: ont_pwd, did: did, dev: dev, fn: frame_number,
                sn: slot_number, pn: port_number, ont_id: ont_id, run_stat: run_stat, onu_did: onu_did,
                onu_dev: onu_dev
              ),
              payload: hash_to_string(
                show_option: __show_option(*show_option)
              )
            )
          end
        end
      end
    end
  end
end
