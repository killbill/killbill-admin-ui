# frozen_string_literal: true

module Kaui
  class InvoiceTagsController < Kaui::EngineController
    def edit
      @invoice_id = params.require(:invoice_id)

      cached_options_for_klient = options_for_klient
      fetch_tag_names = promise { Kaui::Tag.all_for_invoice(@invoice_id, false, 'NONE', cached_options_for_klient).map(&:tag_definition_name).sort }
      fetch_available_tags = promise { Kaui::TagDefinition.all_for_invoice(cached_options_for_klient) }

      @tag_names = wait(fetch_tag_names)
      @available_tags = wait(fetch_available_tags)
    end

    def update
      account_id = params.require(:account_id)
      invoice_id = params.require(:invoice_id)

      tags = []
      params.each do |tag, _tag_name|
        tag_info = tag.split('_')
        next if (tag_info.size != 2) || (tag_info[0] != 'tag')

        tags << tag_info[1]
      end

      Kaui::Tag.set_for_invoice(invoice_id, tags, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.invoice_path(invoice_id, account_id:), notice: 'Invoice tags successfully set'
    end
  end
end
