#lib_dir = File.expand_path("..", __FILE__)
#$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "kaui/engine"

module Kaui
  mattr_accessor :killbill_finder
  mattr_accessor :account_home_path
  mattr_accessor :bundle_home_path
  mattr_accessor :invoice_home_path
  mattr_accessor :bundle_key_display_string

  self.killbill_finder = lambda { Kaui::Engine.config.killbill_url }
  self.account_home_path = lambda {|account_id| Kaui::Engine.routes.url_helpers.account_path(account_id) }
  self.bundle_home_path = lambda {|bundle_id| Kaui::Engine.routes.url_helpers.bundle_path(:id => bundle_id) }
  self.invoice_home_path = lambda {|invoice_id| Kaui::Engine.routes.url_helpers.invoice_path(:id => invoice_id) }
  self.bundle_key_display_string =  lambda {|bundle_key| bundle_key }
end
