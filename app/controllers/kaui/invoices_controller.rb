class Kaui::InvoicesController < Kaui::EngineController
  def index
    if params[:id].present?
      redirect_to invoice_path(params[:id])
    end
  end

  def show
    @invoice_id = params[:id]
    if @invoice_id.present?
      @invoice = Kaui::KillbillHelper.get_invoice(@invoice_id)
      if @invoice.present?
        @account = Kaui::KillbillHelper.get_account(@invoice.account_id)
        @subscriptions = {}
        @bundles = {}
        if @invoice.items.present?
          @invoice.items.each do |item|
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
        redirect_to :action => :index
      end
    else
      flash[:error] = "No id given"
    end
  end
end
