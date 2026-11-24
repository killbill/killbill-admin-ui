# frozen_string_literal: true

require 'test_helper'

module Kaui
  # The Kaui administration screens (tenants, users, roles) are closed to the users who signed in through the Cognito
  # token exchange, unless they hold the *:* role (the sidebar hides them, the controllers enforce it).
  #
  # Kill Bill is stubbed (the session is valid, the permissions are given by the test).
  class CognitoAdminScreensTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    Subject = Struct.new(:principal, :is_authenticated)

    ADMIN_PATHS = %w[/kaui/admin_tenants /kaui/admin_allowed_users /kaui/role_definitions].freeze

    setup do
      Kaui::ApplicationRecord.subclasses.each(&:delete_all)
      @user = Kaui::User.create!(kb_username: 'cognito:alice@acme.com', kb_session_id: 'session')
    end

    test 'forbids the admin screens to a bearer user without the *:* role' do
      with_kill_bill_permissions(%w[account:item_adjust]) do
        sign_in @user, scope: :user

        ADMIN_PATHS.each do |path|
          get path
          assert_response :forbidden, path
        end
      end
    end

    test 'lets a bearer user holding the *:* role through' do
      with_kill_bill_permissions(%w[*:*]) do
        sign_in @user, scope: :user

        ADMIN_PATHS.each do |path|
          get path
          assert_not_equal 403, response.status, path
        end
      end
    end

    private

    def with_kill_bill_permissions(permissions, &)
      subject = Subject.new(@user.kb_username, true)
      KillBillClient::Model::Security.stub(:find_subject, subject) do
        Kaui::User.stub(:do_find_permissions, permissions, &)
      end
    end
  end
end
