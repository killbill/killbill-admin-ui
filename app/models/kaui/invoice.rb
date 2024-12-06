# frozen_string_literal: true

module Kaui
  class Invoice < KillBillClient::Model::Invoice
    TABLE_IGNORE_COLUMNS = %w[amount balance credit_adj refund_adj items is_parent_invoice parent_invoice_id parent_account_id audit_logs].freeze

    def self.build_from_raw_invoice(raw_invoice)
      result = Kaui::Invoice.new
      KillBillClient::Model::InvoiceAttributes.instance_variable_get('@json_attributes').each do |attr|
        result.send("#{attr}=", raw_invoice.send(attr))
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

    %i[amount balance credits].each do |type|
      define_method "#{type}_to_money" do
        Kaui::Base.to_money(send(type), currency)
      end
    end

    def refund_adjustment_to_money
      Kaui::Base.to_money(refund_adj, currency)
    end

    def credit_adjustment_to_money
      Kaui::Base.to_money(credit_adj, currency)
    end
  end
end
