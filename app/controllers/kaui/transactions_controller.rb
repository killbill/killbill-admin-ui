class Kaui::TransactionsController < Kaui::EngineController

  def new
    @account_id = params[:account_id]
    @payment_method_id = params[:payment_method_id]
    @transaction = Kaui::Transaction.new(:payment_id => params[:payment_id],
                                         :amount => params[:amount],
                                         :currency => params[:currency],
                                         :transaction_type => params[:transaction_type])
  end

  def create
    transaction = Kaui::Transaction.new(params[:transaction].delete_if { |key, value| value.blank? })

    payment = transaction.create(params.require(:account_id), params[:payment_method_id], current_user.kb_username, params[:reason], params[:comment], options_for_klient)
    redirect_to kaui_engine.account_payment_path(payment.account_id, payment.payment_id), :notice => 'Transaction successfully created'
  end
end
