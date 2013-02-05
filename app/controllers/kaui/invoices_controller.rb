class Kaui::InvoicesController < Kaui::EngineController
  def index
    if params[:invoice_id].present?
      redirect_to kaui_engine.invoice_path(params[:invoice_id])
    end
  end

  def show
    @invoice_id = params[:id]
    if @invoice_id.present?
      begin
        @invoice = Kaui::KillbillHelper.get_invoice(@invoice_id)
        if @invoice.present?
          @account = Kaui::KillbillHelper.get_account(@invoice.account_id)
          @payments = Kaui::KillbillHelper.get_payments(@invoice_id)
          @payment_methods = {}
          @payments.each do |payment|
            # The payment method may have been deleted
            @payment_methods[payment.payment_id] = Kaui::KillbillHelper::get_payment_method(payment.payment_method_id) rescue nil
          end

          @subscriptions = {}
          @bundles = {}
          @cba_items_not_deleteable = []
          if @invoice.items.present?
            @invoice.items.each do |item|
              @cba_items_not_deleteable << item.linked_invoice_item_id if item.description =~ /account credit/ and item.amount < 0

              unless item.subscription_id.nil? || @subscriptions.has_key?(item.subscription_id)
                @subscriptions[item.subscription_id] = Kaui::KillbillHelper.get_subscription(item.subscription_id)
              end
              unless item.bundle_id.nil? || @bundles.has_key?(item.bundle_id)
                @bundles[item.bundle_id] = Kaui::KillbillHelper.get_bundle(item.bundle_id)
              end
          end
          else
            flash[:error] = "Invoice items for #{@invoice_id} not found"
          end
        else
          flash[:error] = "Invoice #{@invoice_id} not found"
          render :action => :index
        end
      rescue => e
        flash[:error] = "Error while getting information for invoice #{@invoice_id}: #{as_string(e)}"
      end
    else
      flash[:error] = "No id given"
    end
  end

  def show_html
    begin
      render :text => Kaui::KillbillHelper.get_invoice_html(params[:id])
    rescue => e
      flash[:error] = "Error rendering invoice html #{invoice_id}: #{as_string(e)}"
    end
  end
end
