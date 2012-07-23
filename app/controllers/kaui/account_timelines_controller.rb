class Kaui::AccountTimelinesController < Kaui::EngineController
  def index
    if params[:account_id].present?
      redirect_to account_timeline_path(params[:account_id])
    end
  end

  def show
    @account_id = params[:id]
    if @account_id.present?
      @account = Kaui::KillbillHelper::get_account(@account_id)

      if @account.present?
        @timeline = Kaui::KillbillHelper::get_account_timeline(@account_id)
        # @payment_attempts_by_payment_id = {}
        @invoices_by_id = {}
        @bundle_names = {}
        unless @timeline.nil?
          @timeline.payments.each do |payment|
            if payment.invoice_id.present? &&
               payment.payment_id.present? &&
               # !@payment_attempts_by_payment_id.has_key?(payment.payment_id)

              @invoices_by_id[payment.invoice_id] = Kaui::KillbillHelper::get_invoice(payment.invoice_id)
              # payment_attempt = Kaui::KillbillHelper::get_payment_attempt(@timeline.account.external_key,
              #                                                             payment.invoice_id,
              #                                                             payment.payment_id)
              # @payment_attempts_by_payment_id[payment.payment_id] = payment_attempt
              payment.bundle_keys.split(",").each do |bundle_key|
                unless @bundle_names.has_key?(bundle_key)
                  @bundle_names[bundle_key] = Kaui.bundle_key_display_string.call(bundle_key)
                end
              end
            end
          end
          @timeline.invoices.each do |invoice|
            if invoice.invoice_id.present? && !@invoices_by_id.has_key?(invoice.invoice_id)
              @invoices_by_id[invoice.invoice_id] = Kaui::KillbillHelper::get_invoice(invoice.invoice_id)
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
      else
        flash[:error] = "Account #{@account_id} not found"
        redirect_to :action => :index
      end
    else
      flash[:notice] = "No id given"
      redirect_to :back
    end
  end
end
