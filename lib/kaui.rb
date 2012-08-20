#lib_dir = File.expand_path("..", __FILE__)
#$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "kaui/engine"

module Kaui
  mattr_accessor :killbill_finder
  mattr_accessor :account_home_path
  mattr_accessor :bundle_home_path
  mattr_accessor :bundle_key_display_string
  mattr_accessor :creditcard_plugin_name

  self.killbill_finder = lambda { Kaui::Engine.config.killbill_url }
  self.account_home_path = lambda {|account_id| Kaui::Engine.routes.url_helpers.account_path(account_id) }
  self.bundle_home_path = lambda {|external_key| Kaui::Engine.routes.url_helpers.bundles_path(:params => { :external_key => external_key }) }
  self.bundle_key_display_string =  lambda {|bundle_key| bundle_key }
  self.creditcard_plugin_name =  lambda { nil }
end
