# frozen_string_literal: true

module Kaui
  class InvoicesController < Kaui::EngineController
    def index
      @search_query = params[:account_id]

      @ordering = params[:ordering] || (@search_query.blank? ? 'desc' : 'asc')
      @offset = params[:offset] || 0
      @limit = params[:limit] || 50

      @max_nb_records = @search_query.blank? ? Kaui::Invoice.list_or_search(nil, 0, 0, options_for_klient).pagination_max_nb_records : 0
    end

    def pagination
      cached_options_for_klient = options_for_klient

      searcher = lambda do |search_key, offset, limit|
        account = begin
          Kaui::Account.find_by_id_or_key(search_key, false, false, cached_options_for_klient)
        rescue StandardError
          nil
        end
        if account.nil?
          Kaui::Invoice.list_or_search(search_key, offset, limit, cached_options_for_klient)
        else
          account.invoices(cached_options_for_klient.merge({ params: { includeVoidedInvoices: true } })).map! { |invoice| Kaui::Invoice.build_from_raw_invoice(invoice) }
        end
      end

      account_id = (params[:search] || {})[:value]
      if account_id.blank?
        # Don't show amount and balance, and they will not be populated
        data_extractor = lambda do |invoice, column|
          [
            invoice.invoice_number.to_i,
            invoice.invoice_date
          ][column]
        end
        formatter = lambda do |invoice|
          row = [view_context.link_to(invoice.invoice_number, view_context.url_for(controller: :invoices, action: :show, account_id: invoice.account_id, id: invoice.invoice_id))]
          row += Kaui.invoice_search_columns.call(invoice, view_context)[1]
          row
        end
      else
        data_extractor = lambda do |invoice, column|
          [
            invoice.invoice_number.to_i,
            invoice.invoice_date,
            invoice.amount,
            invoice.balance,
            invoice.status
          ][column]
        end
        formatter = lambda do |invoice|
          row = [view_context.link_to(invoice.invoice_number, view_context.url_for(controller: :invoices, action: :show, account_id: invoice.account_id, id: invoice.invoice_id))]
          row += Kaui.account_invoices_columns.call(invoice, view_context)[1]
          row
        end
      end

      paginate searcher, data_extractor, formatter
    end

    # rubocop:disable Lint/HashCompareByIdentity
    def show
      # Go to the database once
      cached_options_for_klient = options_for_klient

      @invoice = Kaui::Invoice.find_by_id(params.require(:id), 'FULL', cached_options_for_klient)
      # This will put the TAX items at the bottom
      precedence = {
        'EXTERNAL_CHARGE' => 0,
        'FIXED' => 1,
        'RECURRING' => 2,
        'REPAIR_ADJ' => 3,
        'USAGE' => 4,
        'PARENT_SUMMARY' => 5,
        'ITEM_ADJ' => 6,
        'CBA_ADJ' => 7,
        'CREDIT_ADJ' => 8,
        'TAX' => 9
      }
      # TODO: The pretty description has to be shared with the view
      @invoice.items.sort_by! do |ii|
        # Make sure not to compare nil (ArgumentError comparison of Array with Array failed)
        a = precedence[ii.item_type] || 100
        b = (ii.pretty_plan_name.blank? || !ii.item_type.in?(%w[USAGE RECURRING]) ? ii.description : ii.pretty_plan_name) || ''
        [a, b]
      end

      fetch_payments = promise { @invoice.payments(true, true, 'FULL', cached_options_for_klient).map { |payment| Kaui::InvoicePayment.build_from_raw_payment(payment) } }
      fetch_pms = fetch_payments.then { |payments| Kaui::PaymentMethod.payment_methods_for_payments(payments, cached_options_for_klient) }
      fetch_invoice_fields = promise { @invoice.custom_fields('NONE', cached_options_for_klient).sort { |cf_a, cf_b| cf_a.name.downcase <=> cf_b.name.downcase } }
      fetch_payment_fields = promise do
        all_payment_fields = @account.all_custom_fields(:PAYMENT, 'NONE', cached_options_for_klient)
        all_payment_fields.each_with_object({}) do |entry, hsh|
          (hsh[entry.object_id] ||= []) << entry
        end
      end

      fetch_available_invoice_item_tags = promise { Kaui::TagDefinition.all_for_invoice_item(cached_options_for_klient) }
      fetch_tags_per_invoice_item = promise do
        tags_per_invoice_item = @account.all_tags(:INVOICE_ITEM, false, 'NONE', cached_options_for_klient)
        tags_per_invoice_item.each_with_object({}) do |entry, hsh|
          (hsh[entry.object_id] ||= []) << entry
        end
      end

      fetch_custom_fields_per_invoice_item = promise do
        custom_fields_per_invoice_item = @account.all_custom_fields(:INVOICE_ITEM, 'NONE', cached_options_for_klient)
        custom_fields_per_invoice_item.each_with_object({}) do |entry, hsh|
          (hsh[entry.object_id] ||= []) << entry
        end
      end

      fetch_invoice_tags = promise { @invoice.tags(false, 'NONE', cached_options_for_klient).sort { |tag_a, tag_b| tag_a <=> tag_b } }
      fetch_available_invoice_tags = promise { Kaui::TagDefinition.all_for_invoice(cached_options_for_klient) }

      @payments = wait(fetch_payments)
      @payment_methods = wait(fetch_pms)
      @custom_fields = wait(fetch_invoice_fields)
      @payment_custom_fields = wait(fetch_payment_fields)
      @custom_fields_per_invoice_item = wait(fetch_custom_fields_per_invoice_item)
      @tags_per_invoice_item = wait(fetch_tags_per_invoice_item)
      @available_invoice_item_tags = wait(fetch_available_invoice_item_tags)
      @invoice_tags = wait(fetch_invoice_tags)
      @available_invoice_tags = wait(fetch_available_invoice_tags)
      @available_invoice_tags.reject! { |td| td.name == 'WRITTEN_OFF' } if @invoice.status == 'VOID'
    end
    # rubocop:enable Lint/HashCompareByIdentity

    def void_invoice
      cached_options_for_klient = options_for_klient
      invoice = KillBillClient::Model::Invoice.find_by_id(params.require(:id), 'NONE', cached_options_for_klient)
      begin
        invoice.void(current_user.kb_username, params[:reason], params[:comment], cached_options_for_klient)
        redirect_to account_invoice_path(invoice.account_id, invoice.invoice_id), notice: 'Invoice successfully voided'
      rescue StandardError => e
        flash[:error] = "Unable to void invoice: #{as_string(e)}"
        redirect_to account_invoice_path(invoice.account_id, invoice.invoice_id)
      end
    end

    def restful_show
      invoice = Kaui::Invoice.find_by_id(params.require(:id), 'NONE', options_for_klient)
      redirect_to account_invoice_path(invoice.account_id, invoice.invoice_id)
    end

    def show_html
      render html: Kaui::Invoice.as_html(params.require(:id), options_for_klient).html_safe
    end

    def commit_invoice
      cached_options_for_klient = options_for_klient
      invoice = KillBillClient::Model::Invoice.find_by_id(params.require(:id), 'NONE', cached_options_for_klient)
      invoice.commit(current_user.kb_username, params[:reason], params[:comment], cached_options_for_klient)
      redirect_to account_invoice_path(invoice.account_id, invoice.invoice_id), notice: 'Invoice successfully committed'
    end
  end
end
