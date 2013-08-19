class Kaui::AccountTimelinesController < Kaui::EngineController
  def index
    if params[:account_id].present?
      redirect_to kaui_engine.account_timeline_path(params[:account_id])
    end
  end

  def show
    @account_id = params[:id]
    unless @account_id.present?
      flash[:notice] = "No id given"
      redirect_to :back
      return
    end
    begin
      @account = Kaui::KillbillHelper::get_account(@account_id, false, false, options_for_klient)
      @timeline = Kaui::KillbillHelper::get_account_timeline(@account_id, "MINIMAL", options_for_klient)
    rescue => e
      flash[:error] = "Could not load the account timeline for #{@account_id}: #{as_string(e)}"
      redirect_to :action => :index
      return
    end

    @invoices_by_id = {}
    @bundle_names = {}
    unless @timeline.nil?
      @timeline.payments.each do |payment|
        if payment.invoice_id.present? && payment.payment_id.present?
          begin
            @invoices_by_id[payment.invoice_id] = Kaui::KillbillHelper::get_invoice(payment.invoice_id, true, options_for_klient)
          rescue => e
            flash.now[:error] = "Could not get invoice information for the timeline #{@account_id}: #{as_string(e)}"
          end
          payment.bundle_keys.split(",").each do |bundle_key|
            unless @bundle_names.has_key?(bundle_key)
              @bundle_names[bundle_key] = Kaui.bundle_key_display_string.call(bundle_key)
            end
          end
        end
      end
      @timeline.invoices.each do |invoice|
        if invoice.invoice_id.present? && !@invoices_by_id.has_key?(invoice.invoice_id)
          begin
            @invoices_by_id[invoice.invoice_id] = Kaui::KillbillHelper::get_invoice(invoice.invoice_id, true, options_for_klient)
          rescue => e
            flash.now[:error] = "Could not get invoice information for the timeline #{@account_id}: #{as_string(e)}"
          end
          invoice.bundle_keys.split(",").each do |bundle_key|
            unless @bundle_names.has_key?(bundle_key)
              @bundle_names[bundle_key] = Kaui.bundle_key_display_string.call(bundle_key)
            end
          end
        end
      end
      @timeline.bundles.each do |bundle|
        unless @bundle_names.has_key?(bundle.external_key)
          @bundle_names[bundle.external_key] = Kaui.bundle_key_display_string.call(bundle.external_key)
        end
      end

      if params.has_key?(:external_key)
        @selected_bundle = @bundle_names[params[:external_key]]
      end
    end
  end
end
