# frozen_string_literal: true

module Kaui
  module PaymentHelper
    def transaction_statuses
      Kaui::Payment::TRANSACTION_STATUSES
    end

    def colored_transaction_status(transaction_status)
      data = "<span class='alert-"
      data += if transaction_status == 'SUCCESS'
                "success'>"
              else
                "danger'>"
              end
      data += transaction_status
      data += '</span>'
      data.html_safe
    end

    def gateway_url(payment_method, payment)
      return nil if payment_method.nil? || payment.nil? || payment.transactions.empty?

      template = Kaui.gateways_urls[payment_method.plugin_name]
      return nil if template.nil?

      first_payment_reference_id = payment.transactions.first.first_payment_reference_id
      return nil if first_payment_reference_id.nil?

      template.gsub('FIRST_PAYMENT_REFERENCE_ID', first_payment_reference_id)
    end
  end
end
