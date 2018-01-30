class Kaui::HomeController < Kaui::EngineController

  def index
    @search_query = params[:q]
  end

  def search
    search_type, search_query = parse_query(params[:q])
    if search_type == 'invoice'
      redirect_to invoice_path(:id => search_query)
    elsif search_type == 'payment'
      redirect_to payment_path(:id => search_query)
    elsif search_type == 'transaction'
      redirect_to transaction_path(:id => search_query)
    else
      redirect_to accounts_path(:q => search_query, :fast => params[:fast])
    end
  end

  private

  def parse_query(query)
    /((invoice|payment|transaction):)?(.*)/.match(query).captures.drop(1)
  end
end
