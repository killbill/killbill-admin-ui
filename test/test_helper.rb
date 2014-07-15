# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require 'securerandom'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load helpers
Dir["#{File.dirname(__FILE__)}/unit/helpers/kaui/*.rb"].each { |f| require f }

# Include Devise helpers
class ActionController::TestCase
  include Devise::TestHelpers

  setup do
    @user = Kaui::User.create!({
                                 :kb_tenant_id => "tenant_id_test",
                                 :kb_username => "username_test",
                                 :kb_session_id => "session_id_test"
                               })
    sign_in @user
  end
end

require 'functional/kaui/functional_test_helper'
