# frozen_string_literal: true

require 'killbill_client'

module Kaui
  class User < ApplicationRecord
    devise :killbill_authenticatable, :killbill_registerable

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

    def root?
      Kaui.root_username == kb_username
    end

    def self.do_find_permissions(options = {})
      KillBillClient::Model::Security.find_permissions options
    end
  end
end
