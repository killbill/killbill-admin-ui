require 'killbill_client'

module Kaui
  class User < ActiveRecord::Base
    devise :killbill_authenticatable

    # Managed by Devise
    attr_accessor :password

    attr_accessible :kb_tenant_id, :kb_username, :kb_session_id, :password

    # Called by Devise to perform authentication
    # Throws KillBillClient::API::Unauthorized on failure
    def self.find_permissions(kb_username, kb_password)
      do_find_permissions :username => kb_username,
                          :password => kb_password
    end

    # Called by CanCan to perform authorization
    # Throws KillBillClient::API::Unauthorized on failure
    def permissions(api_key=KillBillClient.api_key, api_secret=KillBillClient.api_secret)
      User.do_find_permissions :session_id => kb_session_id,
                               :api_key => api_key,
                               :api_secret => api_secret
    end

    # Verify the Kill Bill session hasn't timed-out
    def authenticated_with_killbill?()
      KillBillClient.url = Kaui.killbill_finder.call
      subject = KillBillClient::Model::Security.find_subject :session_id => kb_session_id
      subject.is_authenticated
    rescue KillBillClient::API::Unauthorized => e
      false
    end

    private

    def self.do_find_permissions(options = {})
      KillBillClient::Model::Security.find_permissions options
    end
  end
end
