class Kaui::InvoicesController < Kaui::EngineController
  def index
    if params[:invoice_id].present?
      redirect_to kaui_engine.invoice_path(params[:invoice_id])
    end
  end

  def pagination
    json = { :sEcho => params[:sEcho], :iTotalRecords => 0, :iTotalDisplayRecords => 0, :aaData => [] }

    invoices = Kaui::KillbillHelper::get_invoices(params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    json[:iTotalDisplayRecords] = invoices.pagination_total_nb_records
    json[:iTotalRecords] = invoices.pagination_max_nb_records

    invoices.each do |invoice|
      json[:aaData] << [
                         view_context.link_to(invoice.invoice_id, view_context.url_for(:controller => :invoices, :action => :show, :id => invoice.invoice_id)),
                         invoice.invoice_number,
                         view_context.format_date(invoice.invoice_date),
                         view_context.humanized_money_with_symbol(Kaui::Base.to_money(invoice.amount, invoice.currency)),
                         view_context.humanized_money_with_symbol(Kaui::Base.to_money(invoice.balance, invoice.currency))
                       ]
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def show
    invoice_id_or_number = params[:id]
    if invoice_id_or_number.present?
      begin
        @invoice = Kaui::KillbillHelper.get_invoice(invoice_id_or_number, true, "FULL", options_for_klient)
        if @invoice.present?
          @invoice_id = @invoice.invoice_id
          @account = Kaui::KillbillHelper.get_account(@invoice.account_id, false, false, options_for_klient)
          @payments = Kaui::KillbillHelper.get_payments_for_invoice(@invoice_id, options_for_klient)
          @payment_methods = {}
          @payments.each do |payment|
            # The payment method may have been deleted
            @payment_methods[payment.payment_id] = Kaui::KillbillHelper::get_payment_method(payment.payment_method_id, options_for_klient) rescue nil

            #get the refunds for the payment
            payment.refunds = Kaui::KillbillHelper::get_refunds_for_payment(payment.payment_id, options_for_klient) rescue []
          end

          @subscriptions = {}
          @bundles = {}
          @cba_items_not_deleteable = []
          if @invoice.items.present?
            @invoice.items.each do |item|
              @cba_items_not_deleteable << item.linked_invoice_item_id if item.description =~ /account credit/ and item.amount < 0

              unless item.subscription_id.nil? || @subscriptions.has_key?(item.subscription_id)
                @subscriptions[item.subscription_id] = Kaui::KillbillHelper.get_subscription(item.subscription_id, options_for_klient)
              end
              unless item.bundle_id.nil? || @bundles.has_key?(item.bundle_id)
                @bundles[item.bundle_id] = Kaui::KillbillHelper.get_bundle(item.bundle_id, options_for_klient)
              end
          end
          else
            flash.now[:error] = "Invoice items for #{@invoice_id} not found"
          end
        else
          flash.now[:error] = "Invoice #{invoice_id_or_number} not found"
          render :action => :index
        end
      rescue => e
        flash.now[:error] = "Error while getting information for invoice #{invoice_id_or_number}: #{as_string(e)}"
      end
    else
      flash.now[:error] = "No id given"
    end
  end

  def show_html
    begin
      render :text => Kaui::KillbillHelper.get_invoice_html(params[:id], options_for_klient)
    rescue => e
      flash.now[:error] = "Error rendering invoice html #{params[:id]}: #{as_string(e)}"
      render :action => :index
    end
  end
end
