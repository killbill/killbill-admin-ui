class Kaui::ChargebacksController < Kaui::EngineController

  def show
    @payment_id = params[:id]
    if @payment_id.present?
      begin
        data = Kaui::KillbillHelper::get_chargebacks_for_payment(@payment_id, options_for_klient)
      rescue => e
        flash.now[:error] = "Error while getting chargeback information: #{as_string(e)}"
      end
      if data.present?
        @chargeback = Kaui::Chargeback.new(data)
      else
        Rails.logger.warn("Did not get back chargebacks #{response_body}")
      end
    else
      flash.now[:notice] = "No id given"
    end
  end

  def new
    @payment_id = params[:payment_id]
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]

    begin
      @account = Kaui::KillbillHelper::get_account(@account_id, false, false, options_for_klient)
      @payment = Kaui::KillbillHelper::get_payment(@payment_id, options_for_klient)
      @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id, true, "NONE", options_for_klient)
    rescue => e
      flash[:error] = "Error while starting a new chargeback: #{as_string(e)}"
      redirect_to kaui_engine.account_timeline_path(:id => params[:account_id])
    end

    # The payment method may have been deleted
    @payment_method = Kaui::KillbillHelper::get_payment_method(@payment.payment_method_id, options_for_klient) rescue nil

    @chargeback = Kaui::Chargeback.new("paymentId" => @payment_id,
                                       "chargebackAmount" => @payment.amount)
  end

  def create
    chargeback = Kaui::Chargeback.new(params[:chargeback])
    should_cancel_subs = (params[:cancel_all_subs] == "1")

    if chargeback.present?
      begin
        Kaui::KillbillHelper::create_chargeback(chargeback, current_user, params[:reason], params[:comment], options_for_klient)
      rescue => e
        flash[:error] = "Error while creating a new chargeback: #{as_string(e)}"
        redirect_to kaui_engine.account_timeline_path(:id => params[:account_id]) and return
      end

      # Cancel all subscriptions on the account, if required
      if should_cancel_subs
        begin
          bundles = Kaui::KillbillHelper::get_bundles_for_account(params[:account_id], options_for_klient)
          bundles.each do |bundle|
            bundle.subscriptions.each do |subscription|
              # Already cancelled?
              next unless subscription.billing_end_date.blank?

              # Cancel the entitlement immediately but use the default billing policy
              Kaui::KillbillHelper::delete_subscription(subscription.subscription_id, current_user, params[:reason], params[:comment], 'IMMEDIATE', nil, options_for_klient)
            end
          end
        rescue => e
          flash[:error] = "Error while cancelling subscriptions: #{as_string(e)}"
          redirect_to kaui_engine.account_timeline_path(:id => params[:account_id]) and return
        end
      end

      flash[:notice] = "Chargeback created"
    else
      flash[:error] = "No chargeback to process"
    end
    redirect_to kaui_engine.account_timeline_path(:id => params[:account_id])
  end
end
