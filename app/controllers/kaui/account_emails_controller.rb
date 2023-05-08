# frozen_string_literal: true

module Kaui
  class AccountEmailsController < Kaui::EngineController
    def new
      @account_email = Kaui::AccountEmail.new(account_id: params.require(:account_id),
                                              email: params[:email])
    end

    def create
      @account_email = Kaui::AccountEmail.new(account_email_params.merge(account_id: params.require(:account_id)))

      begin
        @account_email.create(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
        redirect_to kaui_engine.account_path(@account_email.account_id), notice: 'Account email was successfully added'
      rescue StandardError => e
        flash.now[:error] = "Error while adding the email: #{as_string(e)}"
        render action: :new
      end
    end

    def destroy
      account_email = Kaui::AccountEmail.new(account_id: params.require(:account_id),
                                             email: params.require(:id))

      account_email.destroy(current_user.kb_username, params[:reason], params[:comment], options_for_klient)

      redirect_to kaui_engine.account_path(account_email.account_id), notice: 'Account email was successfully deleted'
    end

    private

    def account_email_params
      account_email = params.require(:account_email)
      account_email.require(:email)
      account_email
    end
  end
end
