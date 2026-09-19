# frozen_string_literal: true

RSpec.describe Lib::TL1::Huawei::Message::Response do
  subject(:record) { described_class.new(ontid: '1', rxpower: '--', name: 'Office west') }

  it 'retains OpenStruct inheritance and indexed access to raw protocol columns' do
    expect(described_class.superclass.name).to eq('OpenStruct')
    expect(record[:ontid]).to eq('1')
    expect(record[:rxpower]).to eq('--')
    expect(record[:unknown]).to be_nil
  end

  it 'enumerates protocol columns through each_pair with and without a block' do
    expected = [[:ontid, '1'], [:rxpower, '--'], [:name, 'Office west']]

    expect(record.each_pair.to_a).to eq(expected)
    expect { |block| record.each_pair(&block) }.to yield_successive_args(*expected)
  end

  it 'exposes snake_case readers without changing the stored column names or values' do
    expect(record).to respond_to(:ont_id, :rx_power)
    expect(record.ont_id).to eq('1')
    expect(record.rx_power).to eq('--')
    expect(record.to_h).to eq(ontid: '1', rxpower: '--', name: 'Office west')
  end

  it 'reflects indexed writes and dynamic setters in readers and exported data' do
    record[:rxpower] = '-19.5'
    record.ontid = '2'
    record[:newcolumn] = 'Additional value'

    expect(record.rx_power).to eq('-19.5')
    expect(record.ont_id).to eq('2')
    expect(record.new_column).to eq('Additional value')
    expect(record.to_h).to eq(ontid: '2', rxpower: '-19.5', name: 'Office west', newcolumn: 'Additional value')
  end

  it 'returns an independent hash without renaming or adding columns to the record' do
    exported = record.to_h
    exported[:ontid] = 'Changed copy'
    exported[:extra] = 'Copy only'

    expect(record.ont_id).to eq('1')
    expect(record).not_to respond_to(:extra)
    expect(record.to_h).to eq(ontid: '1', rxpower: '--', name: 'Office west')
  end
end
