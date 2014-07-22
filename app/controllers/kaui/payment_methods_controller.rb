class Kaui::PaymentMethodsController < Kaui::EngineController

  def index
  end

  def pagination
    search_key = params[:sSearch]
    offset     = params[:iDisplayStart] || 0
    limit      = params[:iDisplayLength] || 10

    payment_methods = Kaui::PaymentMethod.list_or_search(search_key, offset, limit, options_for_klient)

    json = {
        :sEcho                => params[:sEcho],
        :iTotalRecords        => payment_methods.pagination_max_nb_records,
        :iTotalDisplayRecords => payment_methods.pagination_total_nb_records,
        :aaData               => []
    }

    payment_methods.each do |payment_method|
      info_plugin = payment_method.plugin_info || OpenStruct.new
      json[:aaData] << [
          view_context.link_to(view_context.truncate_uuid(payment_method.payment_method_id), view_context.url_for(:controller => :payment_methods, :action => :show, :id => payment_method.payment_method_id)),
          view_context.link_to(view_context.truncate_uuid(payment_method.account_id), view_context.url_for(:controller => :accounts, :action => :show, :id => payment_method.account_id)),
          info_plugin.external_payment_id,
          find_value_from_properties(info_plugin.properties, 'ccName'),
          find_value_from_properties(info_plugin.properties, 'ccLast4'),
      ]
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def new
    @payment_method = Kaui::PaymentMethod.new(:account_id  => params[:account_id],
                                              :plugin_name => params[:plugin_name] || Kaui.creditcard_plugin_name.call)
  end

  def create
    @payment_method             = Kaui::PaymentMethod.new(params[:payment_method].delete_if { |key, value| value.blank? })
    # Transform "1" into boolean
    @payment_method.is_default  = @payment_method.is_default == '1'
    # Sensible default
    @payment_method.plugin_name ||= Kaui.creditcard_plugin_name.call

    # Instance variables needed in case of failure
    @card_type                  = params[:card_type]
    @card_holder_name           = params[:card_holder_name]
    @expiration_year            = params[:expiration_year]
    @expiration_month           = params[:expiration_month]
    @credit_card_number         = params[:credit_card_number]
    @address1                   = params[:address1]
    @address2                   = params[:address2]
    @city                       = params[:city]
    @postal_code                = params[:postal_code]
    @state                      = params[:state]
    @country                    = params[:country]

    @payment_method.plugin_info = {
        'type'              => 'CreditCard',
        'ccType'            => @card_type,
        'ccName'            => @card_holder_name,
        'ccExpirationMonth' => @expiration_month,
        'ccExpirationYear'  => @expiration_year,
        'ccLast4'           => @credit_card_number[-4, 4],
        'address1'          => @address1,
        'address2'          => @address2,
        'city'              => @city,
        'country'           => @country,
        'zip'               => @postal_code,
        'state'             => @state
    }

    begin
      @payment_method = @payment_method.create(current_user.kb_username, @reason, @comment, options_for_klient)
      redirect_to payment_method_path(@payment_method.payment_method_id), :notice => 'Payment method was successfully created'
    rescue => e
      flash.now[:error] = "Error while creating payment method: #{as_string(e)}"
      render :action => :new
    end
  end

  def show
    begin
      @payment_methods = [Kaui::PaymentMethod.find_by_id(params[:id], true, options_for_klient)]
    rescue => e
      flash.now[:error] = "Error while retrieving payment method #{params[:id]}: #{as_string(e)}"
      render :action => :index
    end
  end

  def destroy
    payment_method_id = params[:id]

    begin
      Kaui::PaymentMethod.destroy(payment_method_id, params[:set_auto_pay_off], current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to payment_methods_path, :notice => "Payment method #{payment_method_id} successfully deleted"
    rescue => e
      flash.now[:error] = "Error while deleting payment method #{payment_method_id}: #{as_string(e)}"
      render :action => :index
    end
  end

  private

  def find_value_from_properties(properties, key)
    return nil if key.nil? or properties.nil?
    prop = (properties.find { |kv| kv.key.to_s == key.to_s })
    prop.nil? ? nil : prop.value
  end
end
