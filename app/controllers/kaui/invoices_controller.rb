class Kaui::InvoicesController < Kaui::EngineController

  def index
    if params[:invoice_id].present?
      redirect_to kaui_engine.invoice_path(params[:invoice_id])
    end
  end

  def pagination
    json = {:sEcho => params[:sEcho], :iTotalRecords => 0, :iTotalDisplayRecords => 0, :aaData => []}

    search_key = params[:sSearch]
    if search_key.present?
      invoices = Kaui::Invoice.find_in_batches_by_search_key(search_key, params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    else
      invoices = Kaui::Invoice.find_in_batches(params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    end
    json[:iTotalDisplayRecords] = invoices.pagination_total_nb_records
    json[:iTotalRecords]        = invoices.pagination_max_nb_records

    invoices.each do |invoice|
      json[:aaData] << [
          view_context.link_to(view_context.truncate_uuid(invoice.invoice_id), view_context.url_for(:controller => :invoices, :action => :show, :id => invoice.invoice_id)),
          invoice.invoice_number,
          view_context.format_date(invoice.invoice_date),
          view_context.humanized_money_with_symbol(invoice.amount_to_money),
          view_context.humanized_money_with_symbol(invoice.balance_to_money)
      ]
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def show
    invoice_id_or_number = params[:id]
    unless invoice_id_or_number.present?
      flash.now[:error] = 'No id given'
      render :index and return
    end

    begin
      @invoice         = Kaui::Invoice.find_by_id_or_number(invoice_id_or_number, true, 'FULL', options_for_klient)
      @invoice_id      = @invoice.invoice_id
      @account         = Kaui::Account.find_by_id(@invoice.account_id, false, false, options_for_klient)
      @payments        = Kaui::Invoice.new(:invoice_id => @invoice_id).payments(false, 'FULL', options_for_klient)
      @payment_methods = {}
      @payments.each do |payment|
        # The payment method may have been deleted
        @payment_methods[payment.payment_id] = Kaui::PaymentMethod.find_by_id(payment.payment_method_id, true, options) rescue nil
      end

      @subscriptions            = {}
      @bundles                  = {}
      @cba_items_not_deleteable = []
      if @invoice.items.present?
        @invoice.items.each do |item|
          @cba_items_not_deleteable << item.linked_invoice_item_id if item.description =~ /account credit/ and item.amount < 0

          unless item.subscription_id.nil? || @subscriptions.has_key?(item.subscription_id)
            @subscriptions[item.subscription_id] = Kaui::Subscription::find_by_id(item.subscription_id, options_for_klient)
          end
          unless item.bundle_id.nil? || @bundles.has_key?(item.bundle_id)
            @bundles[item.bundle_id] = Kaui::Bundle::find_by_id(item.bundle_id, options_for_klient)
          end
        end
      else
        flash.now[:error] = "Invoice items for #{@invoice_id} not found"
      end
    rescue => e
      flash.now[:error] = "Error while getting information for invoice #{invoice_id_or_number}: #{as_string(e)}"
    end
  end

  def show_html
    begin
      render :text => Kaui::Invoice.as_html(params[:id], options_for_klient)
    rescue => e
      flash.now[:error] = "Error rendering invoice html #{params[:id]}: #{as_string(e)}"
      render :action => :index
    end
  end
end
