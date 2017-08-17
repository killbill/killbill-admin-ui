module Kaui
  module PaymentHelper

    def transaction_statuses
      Kaui::Payment::TRANSACTION_STATUSES
    end

    def colored_transaction_status(transaction_status)
      data = "<span class='alert-"
      if transaction_status != 'SUCCESS'
        data += "danger'>"
      else
        data += "success'>"
      end
      data += transaction_status
      data += '</span>'
      data.html_safe
    end

    def gateway_url(payment_method, payment)
      return nil if payment_method.nil? || payment.nil? || payment.transactions.empty?

      template = Kaui.gateways_urls[payment_method.plugin_name]
      return nil if template.nil?

      template.gsub('FIRST_PAYMENT_REFERENCE_ID', payment.transactions.first.first_payment_reference_id)
    end
  end
end
