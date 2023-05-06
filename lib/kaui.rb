# frozen_string_literal: true

# lib_dir = File.expand_path("..", __FILE__)
# $LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'kaui/engine'

module Kaui
  mattr_accessor :home_path
  mattr_accessor :tenant_home_path
  mattr_accessor :new_user_session_path
  mattr_accessor :destroy_user_session_path

  mattr_accessor :bundle_details_partial

  mattr_accessor :pretty_account_identifier
  mattr_accessor :bundle_key_display_string
  mattr_accessor :creditcard_plugin_name

  mattr_accessor :account_search_columns
  mattr_accessor :invoice_search_columns
  mattr_accessor :account_invoices_columns

  mattr_accessor :customer_invoice_link

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

  mattr_accessor :gateways_urls

  mattr_accessor :disable_sign_up_link

  self.home_path = -> { Kaui::Engine.routes.url_helpers.home_path }
  self.tenant_home_path = -> { Kaui::Engine.routes.url_helpers.tenants_path }

  self.bundle_details_partial = 'kaui/bundles/bundle_details'

  self.pretty_account_identifier = ->(account) { account.name.presence || account.email.presence || Kaui::UuidHelper.truncate_uuid(account.external_key) }
  self.bundle_key_display_string = ->(bundle_key) { bundle_key }
  self.creditcard_plugin_name =  -> { '__EXTERNAL_PAYMENT__' }

  self.account_search_columns = lambda do |account = nil, view_context = nil|
    [
      ['External key', 'Balance'],
      [
        account&.external_key,
        account.nil? || view_context.nil? ? nil : view_context.humanized_money_with_symbol(account.balance_to_money)
      ]
    ]
  end

  self.invoice_search_columns = lambda do |invoice = nil, view_context = nil|
    default_label = 'label-info'
    default_label = 'label-default' if invoice&.status == 'DRAFT'
    default_label = 'label-success' if invoice&.status == 'COMMITTED'
    default_label = 'label-danger' if invoice&.status == 'VOID'
    [
      %w[Date Status],
      [
        invoice&.invoice_date,
        invoice.nil? || view_context.nil? ? nil : view_context.content_tag(:span, invoice.status, class: ['label', default_label])
      ]
    ]
  end

  self.account_invoices_columns = lambda do |invoice = nil, view_context = nil|
    default_label = 'label-info'
    default_label = 'label-default' if invoice&.status == 'DRAFT'
    default_label = 'label-success' if invoice&.status == 'COMMITTED'
    default_label = 'label-danger' if invoice&.status == 'VOID'
    [
      %w[Date Amount Balance Status],
      [
        invoice&.invoice_date,
        invoice.nil? || view_context.nil? ? nil : view_context.humanized_money_with_symbol(invoice.amount_to_money),
        invoice.nil? || view_context.nil? ? nil : view_context.humanized_money_with_symbol(invoice.balance_to_money),
        invoice.nil? || view_context.nil? ? nil : view_context.content_tag(:span, invoice.status, class: ['label', default_label])
      ]
    ]
  end

  self.customer_invoice_link = ->(invoice, ctx) { ctx.link_to 'View customer invoice html', ctx.kaui_engine.show_html_invoice_path(invoice.invoice_id), class: 'btn', target: '_blank' }

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

  # Default URLs
  self.gateways_urls = {
    'killbill-adyen' => 'https://ca-test.adyen.com/ca/ca/accounts/showTx.shtml?txType=Payment&pspReference=FIRST_PAYMENT_REFERENCE_ID',
    'killbill-cybersource' => 'https://ebctest.cybersource.com/ebctest/transactionsearch/TransactionSearchDetailsLoad.do?requestId=FIRST_PAYMENT_REFERENCE_ID',
    'killbill-stripe' => 'https://dashboard.stripe.com/test/payments/FIRST_PAYMENT_REFERENCE_ID'
  }

  self.disable_sign_up_link = true

  def self.user_assigned_valid_tenant?(user, session)
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

    au.kaui_tenants.select { |t| t.kb_tenant_id == session[:kb_tenant_id] }.first
  end

  def self.current_tenant_user_options(user, session)
    kb_tenant_id = session[:kb_tenant_id]
    user_tenant = Kaui::Tenant.find_by_kb_tenant_id(kb_tenant_id) if kb_tenant_id
    result = {
      username: user.kb_username,
      password: user.password,
      session_id: user.kb_session_id
    }
    if user_tenant
      result[:api_key] = user_tenant.api_key
      result[:api_secret] = user_tenant.api_secret
    end
    result
  end

  def self.config
    {
      layout: layout || 'kaui/layouts/kaui_application'
    }
  end
end

# ruby-1.8 compatibility
module Kernel
  def define_singleton_method(*args, &)
    class << self
      self
    end.send(:define_method, *args, &)
  end
end
