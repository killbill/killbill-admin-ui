require 'killbill_client'

module Kaui
  class User < ActiveRecord::Base
    devise :killbill_authenticatable

    # Throws KillBillClient::API::Unauthorized on failure
    def self.find_permissions(kb_username, kb_password)
      KillBillClient.url = Kaui.killbill_finder.call
      KillBillClient::Model::Security.find_permissions :username => kb_username, :password => kb_password
    end

    def permissions
      User.find_permissions(kb_username, password)
    end
  end
end
