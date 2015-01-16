#lib_dir = File.expand_path("..", __FILE__)
#$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "kaui/engine"

module Kaui

  mattr_accessor :home_path
  mattr_accessor :account_home_path
  mattr_accessor :bundle_home_path
  mattr_accessor :invoice_home_path
  mattr_accessor :tenant_home_path
  mattr_accessor :select_tenant
  mattr_accessor :new_user_session_path

  mattr_accessor :bundle_key_display_string
  mattr_accessor :creditcard_plugin_name
  mattr_accessor :layout

  self.home_path = lambda { Kaui::Engine.routes.url_helpers.home_path }
  self.account_home_path = lambda {|account_id| Kaui::Engine.routes.url_helpers.account_path(account_id) }
  self.bundle_home_path = lambda {|bundle_id| Kaui::Engine.routes.url_helpers.bundle_path(:id => bundle_id) }
  self.invoice_home_path = lambda {|invoice_id| Kaui::Engine.routes.url_helpers.invoice_path(:id => invoice_id) }
  self.tenant_home_path = lambda { Kaui::Engine.routes.url_helpers.tenants_path }
  self.select_tenant = lambda { Kaui::Engine.routes.url_helpers.select_tenant_path }
  self.new_user_session_path = lambda { Kaui::Engine.routes.url_helpers.new_user_session_path }


  self.bundle_key_display_string =  lambda {|bundle_key| bundle_key }
  self.creditcard_plugin_name =  lambda { '__EXTERNAL_PAYMENT__' }

  def self.config(&block)
    # TODO
    {
      :layout => layout || 'kaui/layouts/kaui_application',
    }
  end
end

# ruby-1.8 compatibility
module Kernel
  def define_singleton_method(*args, &block)
    class << self
      self
    end.send(:define_method, *args, &block)
  end
end
