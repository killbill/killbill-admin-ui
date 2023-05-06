# frozen_string_literal: true

require 'test_helper'

module Kaui
  class LoginProxyControllerTest < Kaui::FunctionalTestHelper
    test 'should redirect to' do
      get :check_login, params: { path: home_path }
      assert_redirected_to home_path
    end
  end
end
