class Kaui::AccountEmailsController < Kaui::EngineController

  def new
    @account_email = Kaui::AccountEmail.new(:account_id => params.require(:account_id))
  end

  def create
    @account_email = Kaui::AccountEmail.new(account_email_params)

    account = Kaui::Account.new(:account_id => params.require(:account_id))
    begin
      account.add_email(@account_email.email, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.account_path(account.account_id), :notice => 'Account email was successfully added'
    rescue => e
      flash.now[:error] = "Error while adding the email: #{as_string(e)}"
      render :action => :new
    end
  end

  def destroy
    account = Kaui::Account.new(:account_id => params.require(:account_id))

    account.remove_email(params.require(:id), current_user.kb_username, params[:reason], params[:comment], options_for_klient)

    redirect_to kaui_engine.account_path(account.account_id), :notice => 'Account email was successfully deleted'
  end

  private

  def account_email_params
    account_email = params.require(:account_email)
    account_email.require(:email)
    account_email
  end
end
