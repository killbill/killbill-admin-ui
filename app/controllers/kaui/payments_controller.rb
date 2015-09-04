class Kaui::PaymentsController < Kaui::EngineController

  def index
    @search_query = params[:account_id]
  end

  def pagination
    searcher = lambda do |search_key, offset, limit|
      account = Kaui::Account::find_by_id_or_key(search_key, false, false, options_for_klient) rescue nil
      if account.nil?
        payments = Kaui::Payment.list_or_search(search_key, offset, limit, options_for_klient)
      else
        payments = account.payments(options_for_klient).map! { |payment| Kaui::Payment.build_from_raw_payment(payment) }
      end

      payments.each do |payment|
        created_date = nil
        payment.transactions.each do |transaction|
          transaction_date = Date.parse(transaction.effective_date)
          if created_date.nil? or transaction_date < created_date
            created_date = transaction_date
          end
        end
        payment.payment_date = created_date
      end

      payments
    end

    data_extractor = lambda do |payment, column|
      [
          payment.payment_number.to_i,
          payment.payment_date,
          payment.paid_amount_to_money,
          payment.returned_amount_to_money
      ][column]
    end

    formatter = lambda do |payment|
      [
          view_context.link_to(payment.payment_number, view_context.url_for(:controller => :payments, :action => :show, :account_id => payment.account_id, :id => payment.payment_id)),
          view_context.format_date(payment.payment_date),
          view_context.humanized_money_with_symbol(payment.paid_amount_to_money),
          view_context.humanized_money_with_symbol(payment.returned_amount_to_money)
      ]
    end

    paginate searcher, data_extractor, formatter
  end

  def new
    @invoice = Kaui::Invoice.find_by_id_or_number(params.require(:invoice_id), true, 'NONE', options_for_klient)
    @account = Kaui::Account.find_by_id(params.require(:account_id), false, false, options_for_klient)
    @payment = Kaui::InvoicePayment.new('accountId' => @account.account_id, 'targetInvoiceId' => @invoice.invoice_id, 'purchasedAmount' => @invoice.balance)
  end

  def create
    payment = Kaui::InvoicePayment.new(invoice_payment_params)
    payment = payment.create(params[:external] == '1', current_user.kb_username, params[:reason], params[:comment], options_for_klient)
    redirect_to kaui_engine.account_invoice_path(payment.account_id, payment.target_invoice_id), :notice => 'Payment created'
  end

  def show
    @payment = Kaui::InvoicePayment.find_by_id(params.require(:id), true, options_for_klient)
    @account = Kaui::Account.find_by_id(@payment.account_id, false, false, options_for_klient)
    # The payment method may have been deleted
    @payment_method = Kaui::PaymentMethod.find_by_id(@payment.payment_method_id, true, options_for_klient) rescue nil
  end

  def restful_show
    payment = Kaui::InvoicePayment.find_by_id(params.require(:id), options_for_klient)
    redirect_to account_payment_path(payment.account_id, payment.payment_id)
  end

  private

  def invoice_payment_params
    invoice_payment = params.require(:invoice_payment)
    invoice_payment.require(:target_invoice_id)
    invoice_payment
  end
end
