class Kaui::InvoicesController < Kaui::EngineController

  def index
    @search_query = params[:account_id]

    @ordering = params[:ordering] || (@search_query.blank? ? 'desc' : 'asc')
    @offset = params[:offset] || 0
    @limit = params[:limit] || 50

    @max_nb_records = @search_query.blank? ? Kaui::Invoice.list_or_search(nil, 0, 0, options_for_klient).pagination_max_nb_records : 0
  end

  def pagination
    searcher = lambda do |search_key, offset, limit|
      account = Kaui::Account::find_by_id_or_key(search_key, false, false, options_for_klient) rescue nil
      if account.nil?
        Kaui::Invoice.list_or_search(search_key, offset, limit, options_for_klient)
      else
        account.invoices(true, options_for_klient).map! { |invoice| Kaui::Invoice.build_from_raw_invoice(invoice) }
      end
    end

    data_extractor = lambda do |invoice, column|
      [
          invoice.invoice_number.to_i,
          invoice.invoice_date,
          invoice.amount,
          invoice.balance
      ][column]
    end

    formatter = lambda do |invoice|
      [
          view_context.link_to(invoice.invoice_number, view_context.url_for(:controller => :invoices, :action => :show, :account_id => invoice.account_id, :id => invoice.invoice_id)),
          invoice.invoice_date,
          view_context.humanized_money_with_symbol(invoice.amount_to_money),
          view_context.humanized_money_with_symbol(invoice.balance_to_money)
      ]
    end

    paginate searcher, data_extractor, formatter
  end

  def show
    # Go to the database once
    cached_options_for_klient = options_for_klient

    @invoice = Kaui::Invoice.find_by_id(params.require(:id), true, 'FULL', cached_options_for_klient)

    fetch_payments = promise { @invoice.payments(true, true, 'FULL', cached_options_for_klient).map { |payment| Kaui::InvoicePayment.build_from_raw_payment(payment) } }
    fetch_pms = fetch_payments.then { |payments| Kaui::PaymentMethod.payment_methods_for_payments(payments, cached_options_for_klient) }
    fetch_invoice_fields = promise { @invoice.custom_fields('NONE', cached_options_for_klient).sort { |cf_a, cf_b| cf_a.name.downcase <=> cf_b.name.downcase } }
    fetch_payment_fields = promise {
      all_payment_fields = @account.all_custom_fields(:PAYMENT, 'NONE', cached_options_for_klient)
      all_payment_fields.inject({}) { |hsh, entry| (hsh[entry.object_id] ||= []) << entry; hsh }
    }

    fetch_available_invoice_item_tags = promise { Kaui::TagDefinition.all_for_invoice_item(cached_options_for_klient) }
    fetch_tags_per_invoice_item = promise {
      tags_per_invoice_item = @account.all_tags(:INVOICE_ITEM, false, 'NONE', cached_options_for_klient)
      tags_per_invoice_item.inject({}) {|hsh, entry| (hsh[entry.object_id] ||= []) << entry; hsh}
    }

    fetch_custom_fields_per_invoice_item = promise {
      custom_fields_per_invoice_item = @account.all_custom_fields(:INVOICE_ITEM, 'NONE', cached_options_for_klient)
      custom_fields_per_invoice_item.inject({}) { |hsh, entry| (hsh[entry.object_id] ||= []) << entry; hsh }
    }

    @payments = wait(fetch_payments)
    @payment_methods = wait(fetch_pms)
    @custom_fields = wait(fetch_invoice_fields)
    @payment_custom_fields = wait(fetch_payment_fields)
    @custom_fields_per_invoice_item = wait(fetch_custom_fields_per_invoice_item)
    @tags_per_invoice_item = wait(fetch_tags_per_invoice_item)
    @available_invoice_item_tags = wait(fetch_available_invoice_item_tags)
  end

  def restful_show
    invoice = Kaui::Invoice.find_by_id(params.require(:id), false, 'NONE', options_for_klient)
    redirect_to account_invoice_path(invoice.account_id, invoice.invoice_id)
  end

  def show_html
    render :plain => Kaui::Invoice.as_html(params.require(:id), options_for_klient)
  end

  def commit_invoice
    invoice = KillBillClient::Model::Invoice.find_by_id(params.require(:id), false, 'NONE', options_for_klient)
    invoice.commit(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
    redirect_to account_invoice_path(invoice.account_id, invoice.invoice_id), :notice => 'Invoice successfully committed'
  end
end
