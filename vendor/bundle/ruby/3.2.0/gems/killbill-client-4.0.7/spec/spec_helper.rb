$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'bundler'
require 'killbill_client'

require 'logger'

require 'rspec'

KillBillClient.url = 'http://127.0.0.1:8080'
KillBillClient.username = 'admin'
KillBillClient.password = 'password'

KillBillClient.logger = Logger.new(STDOUT)

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = 'documentation'

  config.before(:each, :integration => true) do
    # Setup a tenant for that test
    KillBillClient.api_key = Time.now.to_i.to_s + rand(100).to_s
    KillBillClient.api_secret = 'S4cr3333333t!!!!!!lolz'

    tenant = KillBillClient::Model::Tenant.new
    tenant.api_key = KillBillClient.api_key
    tenant.api_secret = KillBillClient.api_secret
    tenant.create(true, 'KillBill Spec test')
  end
end

begin
  require 'securerandom'
  SecureRandom.uuid
rescue LoadError, NoMethodError
  # See http://jira.codehaus.org/browse/JRUBY-6176
  module SecureRandom
    def self.uuid
      ary = self.random_bytes(16).unpack("NnnnnN")
      ary[2] = (ary[2] & 0x0fff) | 0x4000
      ary[3] = (ary[3] & 0x3fff) | 0x8000
      "%08x-%04x-%04x-%04x-%04x%08x" % ary
    end unless respond_to?(:uuid)
  end
end
