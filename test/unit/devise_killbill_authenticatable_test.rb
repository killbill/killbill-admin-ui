# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support/concern'
require_relative '../../lib/devise/models/killbill_authenticatable'

module Kaui
  class User
    def self.find_permissions(_creds); end
  end
end

class DeviseKillbillAuthenticatableTest < Minitest::Test
  SessionResponse = Struct.new(:session_id)
  ErrorRequest = Struct.new(:unused)
  ErrorResponse = Struct.new(:body)

  DummyUser = Class.new do
    include Devise::Models::KillbillAuthenticatable

    attr_accessor :kb_session_id
  end

  def setup
    @dummy_user = DummyUser.new
  end

  def test_valid_killbill_password_retries_not_found_then_succeeds
    calls = 0

    Kaui::User.stub(:find_permissions, lambda { |_creds|
      calls += 1
      raise killbill_not_found if calls < 3

      SessionResponse.new('session-123')
    }) do
      @dummy_user.stub(:sleep, nil) do
        assert @dummy_user.valid_killbill_password?(username: 'john', password: 'secret')
      end
    end

    assert_equal 3, calls
    assert_equal 'session-123', @dummy_user.kb_session_id
  end

  def test_valid_killbill_password_returns_false_on_unauthorized
    Kaui::User.stub(:find_permissions, ->(_creds) { raise killbill_unauthorized }) do
      assert_equal false, @dummy_user.valid_killbill_password?(username: 'john', password: 'wrong')
    end
  end

  private

  def killbill_not_found
    KillBillClient::API::NotFound.new(ErrorRequest.new(nil), ErrorResponse.new('{"message":"Failed to find user"}'))
  end

  def killbill_unauthorized
    KillBillClient::API::Unauthorized.new(ErrorRequest.new(nil), ErrorResponse.new('{"message":"Invalid credentials"}'))
  end
end
