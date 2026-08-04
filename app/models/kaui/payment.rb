# frozen_string_literal: true

module Kaui
  class Payment < KillBillClient::Model::Payment
    include Kaui::PaymentState

    attr_accessor :payment_date, :target_invoice_id

    TRANSACTION_STATUSES = %w[SUCCESS PENDING PAYMENT_FAILURE PLUGIN_FAILURE UNKNOWN].freeze
    # Columns shown by default on the Payments list screen (demo-friendly defaults); the rest remain
    # available but hidden until the user opts in via "Edit Columns".
    DEFAULT_VISIBLE_COLUMNS = %w[payment_date payment_number status account_id currency purchased_amount refunded_amount credited_amount].freeze
    REMAPPING_FIELDS = {
      'auth_amount' => 'auth',
      'captured_amount' => 'capture',
      'purchased_amount' => 'purchase',
      'credited_amount' => 'credit',
      'refunded_amount' => 'refund'
    }.freeze
    ADVANCED_SEARCH_COLUMNS = %w[id account_id payment_method_id external_key].freeze
    ADVANCED_SEARCH_NAME_CHANGES = [%w[ac_id account_id]].freeze

    def self.build_from_raw_payment(raw_payment)
      result = Kaui::Payment.new
      KillBillClient::Model::PaymentAttributes.instance_variable_get(:@json_attributes).each do |attr|
        result.send("#{attr}=", raw_payment.send(attr))
      end
      result
    end

    def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
      if search_key.present?
        find_in_batches_by_search_key(search_key, offset, limit, options)
      else
        find_in_batches(offset, limit, options)
      end
    end

    %i[auth captured purchased refunded credited].each do |type|
      define_method "#{type}_amount_to_money" do
        Kaui::Base.to_money(send("#{type}_amount"), currency)
      end
    end
  end
end
