require_relative "input"

module Lib
  module TL1
    module Huawei
      module Message
        class Login < Lib::TL1::Huawei::Message::Input
          attr_reader :password, :username

          def initialize(username:, password:)
            @username = username
            @password = password
            super(payload: "UN=#{username},PWD=#{password}")
          end

        end
      end
    end
  end
end