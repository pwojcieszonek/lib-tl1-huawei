# frozen_string_literal: true

require_relative 'input'
module Lib
  module TL1
    module Huawei
      module Message
        # Queries detailed ONT information by location, name, or alias.
        class LstOntDetail < Lib::TL1::Huawei::Message::Input
          attr_reader :did, :dev, :frame_number, :slot_number, :port_number, :ont_id,
                      :ont_name, :ont_alias, :show_option

          def initialize(
            did: nil, dev: nil, frame_number: nil, slot_number: nil, port_number: nil, ont_id: nil,
            ont_name: nil, ont_alias: nil, show_option: []
          )
            set_attributes(
              did:, dev:, frame_number:, slot_number:, port_number:, ont_id:, ont_name:, ont_alias:,
              show_option:
            )
            super(
              aid: hash_to_string(
                did: did, dev: dev, fn: frame_number, sn: slot_number, pn: port_number,
                ont_id: ont_id, name: ont_name, alias: ont_alias
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
