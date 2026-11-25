# frozen_string_literal: true

require 'killbill_client'

module Kaui
  class User < ApplicationRecord
    devise :killbill_authenticatable, :killbill_registerable

    # Principal prefix reported by the Cognito realm of Kill Bill for the users who signed in with a Cognito token (bearer mode of the exchange)
    COGNITO_PRINCIPAL_PREFIX = 'cognito:'

    # Managed by Devise
    attr_accessor :password

    # Called by Devise to perform authentication
    # Throws KillBillClient::API::Unauthorized on failure
    def self.find_permissions(options)
      do_find_permissions(options)
    end

    # Called by CanCan to perform authorization
    # Throws KillBillClient::API::Unauthorized on failure
    def permissions
      User.do_find_permissions session_id: kb_session_id
    end

    # Verify the Kill Bill session hasn't timed-out (ran as part of Warden::Proxy#set_user)
    def authenticated_with_killbill?
      subject = KillBillClient::Model::Security.find_subject session_id: kb_session_id
      subject.is_authenticated
    rescue Errno::ECONNREFUSED, KillBillClient::API::Unauthorized => _e
      false
    end

    # True for the users signed in through the Cognito token exchange without Kill Bill credentials: they have no password to sign in again
    def cognito_principal?
      kb_username.to_s.start_with?(COGNITO_PRINCIPAL_PREFIX)
    end

    def root?
      Kaui.root_username == kb_username
    end

    def self.do_find_permissions(options = {})
      KillBillClient::Model::Security.find_permissions options
    end
  end
end
