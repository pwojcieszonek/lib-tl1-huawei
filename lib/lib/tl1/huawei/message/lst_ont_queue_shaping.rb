# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        # Queries traffic shaping parameters for an ONT queue.
        class LstOntQueueShaping < Lib::TL1::Huawei::Message::Input
          attr_reader :did, :dev, :frame_number, :slot_number, :port_number, :ont_id, :ont_name, :ont_alias, :queue_id

          def initialize(
            did: nil, dev: nil, frame_number: nil, slot_number: nil, port_number: nil, ont_id: nil,
            ont_name: nil, ont_alias: nil, queue_id: nil
          )
            set_attributes(
              did:, dev:, frame_number:, slot_number:, port_number:, ont_id:, ont_name:, ont_alias:,
              queue_id:
            )
            super(
              aid: hash_to_string(
                did: did, dev: dev, fn: frame_number, sn: slot_number, pn: port_number,
                ont_id: ont_id, name: ont_name, alias: ont_alias, queue_id: queue_id
              )
            )
          end

          alias fn frame_number
          alias pn port_number
          alias sn slot_number
        end
      end
    end
  end
end
