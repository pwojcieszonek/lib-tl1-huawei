# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        class LstDev < Lib::TL1::Huawei::Message::Input

          attr_reader :did, :dev, :dev_ip, :dev_type, :dev_ver, :onu_locate_info, :showoption, :user_id

          def initialize(
            did: nil,
            dev: nil,
            dev_ip: nil,
            dev_type: nil,
            dev_ver: nil,
            onu_locate_info: nil,
            show_option: [],
            user_id: nil
          )

            @did = did
            @dev = dev
            @dev_ip = dev_ip
            @dt = dev_type
            @dev_ver = dev_ver
            @onu_locate_info = onu_locate_info
            @show_option = show_option
            @user_id = user_id

            super(
              aid: hash_to_string(
                did: did,
                dev: dev,
                dev_ip: dev_ip,
                dt: dev_type,
                dev_ver: dev_ver,
                onu_locate_info: onu_locate_info
              ),
              payload: hash_to_string(
                show_option: __show_option(*show_option),
                user_id: user_id
              )
            )

          end
        end
      end
    end
  end
end