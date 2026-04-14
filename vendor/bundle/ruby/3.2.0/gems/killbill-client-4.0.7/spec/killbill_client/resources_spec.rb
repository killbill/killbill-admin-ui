require 'spec_helper'

describe KillBillClient::Model::Resources do
  it 'should respect the next page url when calling the .each_in_batches method' do
    stuff = KillBillClient::Model::Resources.new
    1.upto(10).each { |i| stuff << i }
    expect(stuff.size).to eq(10)

    idx = 1
    stuff.each_in_batches do |i|
      expect(i).to eq(idx)
      idx += 1
    end
  end
end
