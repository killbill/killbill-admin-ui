#lib_dir = File.expand_path("..", __FILE__)
#$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

if defined?(JRUBY_VERSION)
  require 'core_ext'
end

require "kaui/engine"

module Kaui

  mattr_accessor :home_path
  mattr_accessor :tenant_home_path
  mattr_accessor :new_user_session_path
  mattr_accessor :destroy_user_session_path

  mattr_accessor :bundle_key_display_string
  mattr_accessor :creditcard_plugin_name
  mattr_accessor :layout

  mattr_accessor :thread_pool

  mattr_accessor :demo_mode

  mattr_accessor :root_username
  mattr_accessor :root_password
  mattr_accessor :root_api_key
  mattr_accessor :root_api_secret

  mattr_accessor :default_roles

  mattr_accessor :chargeback_reason_codes
  mattr_accessor :credit_reason_codes
  mattr_accessor :invoice_item_reason_codes
  mattr_accessor :invoice_payment_reason_codes
  mattr_accessor :payment_reason_codes
  mattr_accessor :refund_reason_codes

  self.home_path = lambda { Kaui::Engine.routes.url_helpers.home_path }
  self.tenant_home_path = lambda { Kaui::Engine.routes.url_helpers.tenants_path }

  self.bundle_key_display_string =  lambda {|bundle_key| bundle_key }
  self.creditcard_plugin_name =  lambda { '__EXTERNAL_PAYMENT__' }

  self.demo_mode = false

  # Root credentials for SaaS operations
  self.root_username = 'admin'
  self.root_password = 'password'
  self.root_api_key = 'bob'
  self.root_api_secret = 'lazar'

  # Default roles for sign-ups
  self.default_roles = ['tenant_admin']

  # Default reason codes
  self.chargeback_reason_codes = ['400 - Canceled Recurring Transaction',
                                  '401 - Cardholder Disputes Quality of Goods or Services',
                                  '402 - Cardholder Does Not Recognize Transaction',
                                  '403 - Cardholder Request Due to Dispute',
                                  '404 - Credit Not Processed',
                                  '405 - Duplicate Processing',
                                  '406 - Fraud Investigation',
                                  '407 - Fraudulent Transaction - Card Absent Environment',
                                  '408 - Incorrect Transaction Amount or Account Number',
                                  '409 - No Cardholder Authorization',
                                  '410 - Non receipt of Merchandise',
                                  '411 - Not as Described or Defective Merchandise',
                                  '412 - Recurring Payment',
                                  '413 - Request for Copy Bearing Signature',
                                  '414 - Requested Transaction Data Not Received',
                                  '415 - Services Not Provided or Merchandise not Received',
                                  '416 - Transaction Amount Differs',
                                  '417 - Validity Challenged',
                                  '418 - Unauthorized Payment',
                                  '419 - Unauthorized Claim',
                                  '420 - Not as Described',
                                  '499 - OTHER']

  self.credit_reason_codes = ['100 - Courtesy',
                              '101 - Billing Error',
                              '199 - OTHER']

  self.invoice_item_reason_codes = ['100 - Courtesy',
                                    '101 - Billing Error',
                                    '199 - OTHER']

  self.invoice_payment_reason_codes = ['600 - Alt payment method',
                                       '699 - OTHER']

  self.payment_reason_codes = ['600 - Alt payment method',
                               '699 - OTHER']

  self.refund_reason_codes = ['500 - Courtesy',
                              '501 - Billing Error',
                              '502 - Alt payment method',
                              '599 - OTHER']

  def self.is_user_assigned_valid_tenant?(user, session)
    #
    # If those are set in config initializer then we bypass the check
    # For multi-tenant production deployment, those should not be set!
    #
    return true if KillBillClient.api_key.present? && KillBillClient.api_secret.present?

    # Not tenant in the session, returns right away...
    return false if session[:kb_tenant_id].nil?

    # Signed-out?
    return false if user.nil?

    # If there is a kb_tenant_id in the session then we check if the user is allowed to access it
    au = Kaui::AllowedUser.find_by_kb_username(user.kb_username)
    return false if au.nil?

    return au.kaui_tenants.select { |t| t.kb_tenant_id == session[:kb_tenant_id] }.first
  end

  def self.current_tenant_user_options(user, session)
    kb_tenant_id = session[:kb_tenant_id]
    user_tenant = Kaui::Tenant.find_by_kb_tenant_id(kb_tenant_id) if kb_tenant_id
    result = {
        :username => user.kb_username,
        :password => user.password,
        :session_id => user.kb_session_id,
    }
    if user_tenant
      result[:api_key] = user_tenant.api_key
      result[:api_secret] = user_tenant.api_secret
    end
    result
  end




  def self.config(&block)
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
