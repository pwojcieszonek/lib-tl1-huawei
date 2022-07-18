# frozen_string_literal: true

require_relative 'input'

module Lib
  module TL1
    module Huawei
      module Message
        class LstGponLineProfile < Lib::TL1::Huawei::Message::Input
          attr_reader :did, :dev, :prof_id

          def initialize(did: nil, dev: nil, prof_id: nil)
            @did = did
            @dev = dev
            @prof_id = prof_id
            super(
              payload: hash_to_string(
                did: did, dev: dev, prof_id: prof_id
              )
            )
          end
        end
      end
    end
  end
end
