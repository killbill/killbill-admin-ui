# Dependencies
#
# Sigh. Rails autoloads the gems specified in the Gemfile and nothing else.
# We need to explicitly require all of our dependencies listed in kaui.gemspec
#
# See also https://github.com/carlhuda/bundler/issues/49
require 'jquery-rails'
require 'jquery-datatables-rails'
require 'd3_rails'
require 'json'
require 'money-rails'
require 'killbill_client'
require 'devise'
require 'cancan'
require 'carmen-rails'
require 'protected_attributes'

module Kaui
  class Engine < ::Rails::Engine
    isolate_namespace Kaui

    initializer 'kaui_engine.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper Kaui::DateHelper
        helper Kaui::MoneyHelper
        helper Kaui::SubscriptionHelper
        helper Kaui::UuidHelper
      end
    end
  end
end
