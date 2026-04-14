require 'spec_helper'

describe KillBillClient::API::ResponseError do
  describe '::error_for' do
    let(:request) { double('request') }
    let(:response) { double('response') }
    before do
      allow(response).to receive(:body)
      allow(response).to receive(:code)
    end

    it 'maps 402 errors' do
      error = described_class.error_for(402, request, response)

      expect(error).to be_a(KillBillClient::API::PaymentRequired)
      expect(error.request).to eq(request)
      expect(error.response).to eq(response)
    end

    it 'maps 422 errors' do
      error = described_class.error_for(422, request, response)

      expect(error).to be_a(KillBillClient::API::UnprocessableEntity)
      expect(error.request).to eq(request)
      expect(error.response).to eq(response)
    end

    it 'maps 502 errors' do
      error = described_class.error_for(502, request, response)

      expect(error).to be_a(KillBillClient::API::GatewayError)
      expect(error.request).to eq(request)
      expect(error.response).to eq(response)
    end

    it 'maps 503 errors' do
      error = described_class.error_for(503, request, response)

      expect(error).to be_a(KillBillClient::API::ServiceUnavailable)
      expect(error.request).to eq(request)
      expect(error.response).to eq(response)
    end

    it 'maps 504 errors' do
      error = described_class.error_for(504, request, response)

      expect(error).to be_a(KillBillClient::API::GatewayTimeout)
      expect(error.request).to eq(request)
      expect(error.response).to eq(response)
    end
  end
end
