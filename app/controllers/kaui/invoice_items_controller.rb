# frozen_string_literal: true

module Kaui
  class InvoiceItemsController < Kaui::EngineController
    def edit
      invoice_item_id = params.require(:id)
      invoice_id = params.require(:invoice_id)

      # See https://github.com/killbill/killbill/issues/7
      invoice = Kaui::Invoice.find_by_id(invoice_id, 'NONE', options_for_klient)
      @invoice_item = invoice.items.find { |ii| ii.invoice_item_id == invoice_item_id }

      return unless @invoice_item.nil?

      flash[:error] = "Unable to find invoice item #{invoice_item_id}"
      redirect_to account_invoice_path(params.require(:account_id), invoice_id)
    end

    def update
      @invoice_item = Kaui::InvoiceItem.new(params.require(:invoice_item))

      begin
        invoice = @invoice_item.update(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
        redirect_to kaui_engine.account_invoice_path(invoice.account_id, invoice.invoice_id), notice: 'Adjustment item was successfully created'
      rescue StandardError => e
        flash.now[:error] = "Error while adjusting invoice item: #{as_string(e)}"
        render action: :edit
      end
    end

    def destroy
      invoice_item = Kaui::InvoiceItem.new(invoice_item_id: params.require(:id),
                                           invoice_id: params.require(:invoice_id),
                                           account_id: params.require(:account_id))

      invoice_item.delete(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.account_invoice_path(invoice_item.account_id, invoice_item.invoice_id), notice: 'CBA item was successfully deleted'
    end

    def update_tags
      @invoice_item = Kaui::InvoiceItem.new(invoice_item_id: params.require(:id))
      invoice_id = params.require(:invoice_id)
      account_id = params.require(:account_id)
      @invoice_item.account_id = account_id

      tags = []
      params.each do |tag|
        tag_info = tag.split('_')
        next if (tag_info.size != 2) || (tag_info[0] != 'tag')

        tags << tag_info[1]
      end

      @invoice_item.set_tags(tags, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to account_invoice_path(account_id, invoice_id), notice: 'Invoice Item tags successfully set'
    end
  end
end
