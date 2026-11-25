# frozen_string_literal: true

require 'test_helper'

module Kaui
  # A user whose Kill Bill session expired is sent to the sign-in form, except when they have no Kill Bill credentials
  # (Cognito token exchange): they are told to reopen Kaui from the application they came from.
  #
  # Kill Bill is stubbed (the session is reported as not authenticated).
  class CognitoSessionExpiryTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    Subject = Struct.new(:principal, :is_authenticated)

    setup do
      Kaui::ApplicationRecord.subclasses.each(&:delete_all)
    end

    test 'sends a bearer user to the session expired page' do
      user = Kaui::User.create!(kb_username: 'cognito:alice@acme.com', kb_session_id: 'expired')

      with_expired_kill_bill_session do
        sign_in user, scope: :user
        get '/kaui/accounts'
      end

      assert_redirected_to 'http://www.example.com/kaui/sso/cognito/session_expired'
      follow_redirect!
      assert_response :ok
      assert_match(/reopen Kaui/, response.body)
    end

    test 'sends a basic user to the sign-in form' do
      user = Kaui::User.create!(kb_username: 'bob', kb_session_id: 'expired')

      with_expired_kill_bill_session do
        sign_in user, scope: :user
        get '/kaui/accounts'
      end

      assert_redirected_to 'http://www.example.com/kaui/users/sign_in'
    end

    private

    def with_expired_kill_bill_session(&)
      KillBillClient::Model::Security.stub(:find_subject, Subject.new(nil, false), &)
    end
  end
end
