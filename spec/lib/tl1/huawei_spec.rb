# frozen_string_literal: true

RSpec.describe Lib::TL1::Huawei do
  it 'exposes the library version number' do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end

  it 'loads the builders and parser through the main entry point' do
    expect(described_class::Message::Login).to be < Lib::TL1::Message::Input
    expect(described_class::Message::Output).to be < Lib::TL1::Message::Output
    expect(described_class::Message::Response.new(did: 'OLT-1').did).to eq('OLT-1')
  end

  it 'builds a complete login command with a stable CTAG' do
    # U2000 TL1 NBI User Guide, §13.1.1 (LOGIN).
    message = described_class::Message::Login.new(username: 'test-user', password: 'example-password')
    message.ctag = 123

    expect(message.to_s).to eq('LOGIN:::123::UN=test-user,PWD=example-password;')
  end
end
