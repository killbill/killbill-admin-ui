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
  end
end
