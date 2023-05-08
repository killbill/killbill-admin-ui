# frozen_string_literal: true

module Kaui
  class ChargesController < Kaui::EngineController
    def new
      invoice_id = params[:invoice_id]
      amount = params[:amount]

      if invoice_id.present?
        @invoice = Kaui::Invoice.find_by_id(invoice_id, 'NONE', options_for_klient)
        amount ||= @invoice.balance
        currency = @invoice.currency
      else
        @invoice = nil
        currency = params[:currency] || 'USD'
      end

      @charge = Kaui::InvoiceItem.new(account_id: params.require(:account_id), invoice_id:, amount:, currency:)
    end

    def create
      charge = Kaui::InvoiceItem.new(params.require(:invoice_item).delete_if { |_key, value| value.blank? })
      charge.account_id ||= params.require(:account_id)

      auto_commit = params[:auto_commit] == '1'

      charge = charge.create(auto_commit, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.account_invoice_path(charge.account_id, charge.invoice_id), notice: 'Charge was successfully created'
    end
  end
end
