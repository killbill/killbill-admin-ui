# frozen_string_literal: true

require 'test_helper'

module Kaui
  # A user whose Kill Bill session expired (or who signs out) is sent to the sign-in form, except when they signed in through
  # the Cognito token exchange: they go back to the application they came from (kaui.cognito.login_url), or are told to
  # reopen Kaui from it when they have no Kill Bill credentials (bearer mode).
  #
  # Kill Bill is stubbed (the session is reported as not authenticated).
  class CognitoSessionExpiryTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    Subject = Struct.new(:principal, :is_authenticated)
    KbResponse = Struct.new(:session_id)
    LOGIN_URL = 'https://aviate.example.com/sign-in'

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

    test 'sends a basic user who came through the exchange back to the login application' do
      exchange_as('bob')

      with_expired_kill_bill_session do
        get '/kaui/accounts'
      end

      assert_redirected_to 'http://www.example.com/kaui/sso/cognito/session_expired'
      with_login_url(LOGIN_URL) { follow_redirect! }
      assert_redirected_to LOGIN_URL
    end

    test 'sends a basic user who came through the exchange to the sign-in form when there is no login url' do
      exchange_as('bob', login_url: nil)

      with_expired_kill_bill_session(login_url: nil) do
        get '/kaui/accounts'
      end

      assert_redirected_to 'http://www.example.com/kaui/users/sign_in'
    end

    test 'sign out sends a user who came through the exchange back to the login application' do
      exchange_as('bob')

      with_login_url(LOGIN_URL) { delete '/kaui/users/sign_out' }

      assert_redirected_to 'http://www.example.com/kaui/sso/cognito/session_expired'
      with_login_url(LOGIN_URL) { follow_redirect! }
      assert_redirected_to LOGIN_URL
    end

    test 'sign out sends a user who came through the exchange to the sign-in form when there is no login url' do
      exchange_as('bob', login_url: nil)

      delete '/kaui/users/sign_out'

      assert_redirected_to 'http://www.example.com/kaui/users/sign_in'
    end

    test 'sign out sends a user who signed in with the form to the sign-in form' do
      user = Kaui::User.create!(kb_username: 'bob', kb_session_id: 'valid')

      with_login_url(LOGIN_URL) do
        sign_in user, scope: :user
        delete '/kaui/users/sign_out'
      end

      assert_redirected_to 'http://www.example.com/kaui/users/sign_in'
    end

    private

    # Signs in through the Cognito token exchange (basic mode), Kill Bill is stubbed
    def exchange_as(kb_username, login_url: LOGIN_URL)
      with_login_url(login_url) do
        Kaui::CognitoJwtVerifier.stub(:configured?, true) do
          Kaui::CognitoJwtVerifier.stub(:verify!, { 'email' => "#{kb_username}@acme.com" }) do
            Kaui::User.stub(:find_permissions, KbResponse.new('kb-session')) do
              KillBillClient::Model::Security.stub(:find_subject, Subject.new(nil, true)) do
                post '/kaui/sso/aviate/exchange', params: { kb_username:, kb_password: 'secret' }, headers: { 'Authorization' => 'Bearer token' }
              end
            end
          end
        end
      end
      assert_response :ok
    end

    def with_login_url(login_url, &)
      Kaui::CognitoJwtVerifier.stub(:login_url, login_url, &)
    end

    def with_expired_kill_bill_session(login_url: LOGIN_URL, &)
      with_login_url(login_url) do
        KillBillClient::Model::Security.stub(:find_subject, Subject.new(nil, false), &)
      end
    end
  end
end
