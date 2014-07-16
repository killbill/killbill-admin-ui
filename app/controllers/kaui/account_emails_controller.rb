class Kaui::AccountEmailsController < Kaui::EngineController

  def show
    @account_id     = params[:id]
    @account_emails = Kaui::AccountEmail.find_all_sorted_by_account_id(@account_id, 'NONE', options_for_klient)
  end

  def new
    @account_email = Kaui::AccountEmail.new(:account_id => params[:account_id])
  end

  def create
    @account_email = Kaui::AccountEmail.new(params[:account_email])

    account = Kaui::Account.new(:account_id => @account_email.account_id)
    begin
      account.add_email(@account_email.email, current_user, params[:reason], params[:comment], options_for_klient)
      redirect_to account_email_path(account.account_id), :notice => 'Account email was successfully added'
    rescue => e
      flash.now[:error] = "Error while adding the email: #{as_string(e)}"
      render :action => :new
    end
  end

  def destroy
    account = Kaui::Account.new(:account_id => params[:id])

    begin
      account.remove_email(params[:email], current_user, params[:reason], params[:comment], options_for_klient)
      redirect_to account_email_path(account.account_id), :notice => 'Account email was successfully deleted'
    rescue => e
      flash.now[:error] = "Error while deleting account email: #{as_string(e)}"
      render :action => :show, :id => account.account_id
    end
  end
end
