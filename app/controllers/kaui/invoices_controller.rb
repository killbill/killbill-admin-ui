class Kaui::InvoicesController < Kaui::EngineController

  def index
    @search_query = params[:account_id]
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
          view_context.format_date(invoice.invoice_date),
          view_context.humanized_money_with_symbol(invoice.amount_to_money),
          view_context.humanized_money_with_symbol(invoice.balance_to_money)
      ]
    end

    paginate searcher, data_extractor, formatter
  end

  def show
    @invoice = Kaui::Invoice.find_by_id_or_number(params.require(:id), true, 'FULL', options_for_klient)

    fetch_payments_and_pms = lambda do
      @payments = @invoice.payments(false, true, 'FULL', options_for_klient).map { |payment| Kaui::InvoicePayment.build_from_raw_payment(payment) }
      @payment_methods = Kaui::PaymentMethod.payment_methods_for_payments(@payments, options_for_klient)
    end
    fetch_account = lambda { @account = Kaui::Account.find_by_id(@invoice.account_id, false, false, options_for_klient) }

    run_in_parallel fetch_payments_and_pms, fetch_account
  end

  def restful_show
    invoice = Kaui::Invoice.find_by_id_or_number(params.require(:id), false, 'NONE', options_for_klient)
    redirect_to account_invoice_path(invoice.account_id, invoice.invoice_id)
  end

  def show_html
    render :text => Kaui::Invoice.as_html(params.require(:id), options_for_klient)
  end
end
