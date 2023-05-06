# frozen_string_literal: true

module Kaui
  class ChargebacksController < Kaui::EngineController
    def new
      payment = Kaui::Payment.find_by_id(params.require(:payment_id), false, false, options_for_klient)
      @chargeback = Kaui::Chargeback.new(payment_id: payment.payment_id,
                                         amount: payment.paid_amount_to_money.to_f,
                                         currency: payment.currency)
    end

    def create
      cached_options_for_klient = options_for_klient

      @chargeback = Kaui::Chargeback.new(params.require(:chargeback))
      should_cancel_subs = (params[:cancel_all_subs] == '1')

      begin
        payment = @chargeback.chargeback(current_user.kb_username, params[:reason], params[:comment], cached_options_for_klient)
      rescue StandardError => e
        flash.now[:error] = "Error while creating a new chargeback: #{as_string(e)}"
        render action: :new and return
      end

      # Cancel all subscriptions on the account, if required
      if should_cancel_subs
        begin
          account = Kaui::Account.find_by_id(payment.account_id, false, false, cached_options_for_klient)
          account.bundles(cached_options_for_klient).each do |bundle|
            bundle.subscriptions.each do |subscription|
              # Already cancelled?
              next unless subscription.billing_end_date.blank?

              # Cancel the entitlement immediately but use the default billing policy
              entitlement = Kaui::Subscription.new(subscription_id: subscription.subscription_id)
              entitlement.cancel_entitlement_immediately(current_user.kb_username, params[:reason], params[:comment], cached_options_for_klient)
            end
          end
        rescue StandardError => e
          flash[:error] = "Error while cancelling subscriptions: #{as_string(e)}"
          render action: :new and return
        end
      end

      redirect_to kaui_engine.account_payment_path(payment.account_id, payment.payment_id), notice: 'Chargeback created'
    end
  end
end
