class Kaui::TransactionsController < Kaui::EngineController

  def new
    @account_id        = params[:account_id]
    @payment_method_id = params[:payment_method_id]
    @transaction       = Kaui::Transaction.new(:payment_id       => params[:payment_id],
                                               :amount           => params[:amount],
                                               :currency         => params[:currency],
                                               :transaction_type => params[:transaction_type])
  end

  def create
    @account_id        = params[:account_id]
    @payment_method_id = params[:payment_method_id]
    @transaction       = Kaui::Transaction.new(params[:transaction].delete_if { |key, value| value.blank? })

    begin
      payment = @transaction.create(@account_id, @payment_method_id, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.account_timeline_path(:id => payment.account_id), :notice => 'Transaction successfully created'
    rescue => e
      flash.now[:error] = "Error while creating a new transaction: #{as_string(e)}"
      render :action => :new
    end
  end
end
