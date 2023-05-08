# frozen_string_literal: true

module Kaui
  class InvoiceItem < KillBillClient::Model::InvoiceItem
    def amount_to_money
      Kaui::Base.to_money(amount, currency)
    end

    def self.amount_to_money(invoice_item)
      new(amount: invoice_item.amount, currency: invoice_item.currency).amount_to_money
    end
  end
end
