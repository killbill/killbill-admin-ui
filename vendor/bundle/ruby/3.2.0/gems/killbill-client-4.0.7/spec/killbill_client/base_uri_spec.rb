require 'spec_helper'

describe KillBillClient do

  it 'should be able to parse a url with http' do
    KillBillClient.url = "http://example.com:8080"
    expect(KillBillClient::API.base_uri.scheme).to eq("http")
    expect(KillBillClient::API.base_uri.host).to eq("example.com")
    expect(KillBillClient::API.base_uri.port).to eq(8080)
  end

  it 'should be able to parse a url without http' do
    KillBillClient.url = "example.com:8080"
    expect(KillBillClient::API.base_uri.scheme).to eq("http")
    expect(KillBillClient::API.base_uri.host).to eq("example.com")
    expect(KillBillClient::API.base_uri.port).to eq(8080)
  end
end
