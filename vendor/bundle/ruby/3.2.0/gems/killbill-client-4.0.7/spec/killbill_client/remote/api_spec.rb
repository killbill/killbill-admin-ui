require 'spec_helper'

describe KillBillClient::API do
  it 'should get all tag definitions', :integration => true  do
    response = KillBillClient::API.get '/1.0/kb/tagDefinitions'
    expect(response.code.to_i).to eq(200)
    tag_definitions = KillBillClient::Model::Resource.from_response KillBillClient::Model::TagDefinition, response
    expect(tag_definitions.size).to be > 1
  end

  it 'requests stacktraces on demand', :integration => true do
    KillBillClient.api_key = Time.now.to_i.to_s + rand(100).to_s
    KillBillClient.api_secret = KillBillClient.api_key

    tenant = KillBillClient::Model::Tenant.new
    tenant.api_key = KillBillClient.api_key
    tenant.api_secret = KillBillClient.api_secret
    tenant.create(true, 'KillBill Spec test')

    begin
      KillBillClient.return_full_stacktraces = true
      tenant.create(true, 'KillBill Spec test')
      fail
    rescue KillBillClient::API::Conflict => e
      billing_exception = JSON.parse(e.response.body)
      expect(billing_exception['className']).to eq('org.killbill.billing.tenant.api.TenantApiException')
      expect(billing_exception['stackTrace'].size).to be >= 71
    ensure
      KillBillClient.return_full_stacktraces = false
    end

    begin
      tenant.create(true, 'KillBill Spec test')
      fail
    rescue KillBillClient::API::Conflict => e
      billing_exception = JSON.parse(e.response.body)
      expect(billing_exception['className']).to eq('org.killbill.billing.tenant.api.TenantApiException')
      expect(billing_exception['stackTrace'].size).to be == 0
    end

    begin
      tenant.create(true, 'KillBill Spec test', nil, nil, {:return_full_stacktraces => true})
      fail
    rescue KillBillClient::API::Conflict => e
      billing_exception = JSON.parse(e.response.body)
      expect(billing_exception['className']).to eq('org.killbill.billing.tenant.api.TenantApiException')
      expect(billing_exception['stackTrace'].size).to be >= 50
    end
  end
end
