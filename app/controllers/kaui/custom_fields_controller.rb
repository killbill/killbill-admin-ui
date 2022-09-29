class Kaui::CustomFieldsController < Kaui::EngineController

  def index




    @search_query = params[:q]

    @ordering = params[:ordering] || (@search_query.blank? ? 'desc' : 'asc')
    @offset = params[:offset] || 0
    @limit = params[:limit] || 50

    @max_nb_records = @search_query.blank? ? Kaui::CustomField.list_or_search(nil, 0, 0, options_for_klient).pagination_max_nb_records : 0
  end

  def pagination
    searcher = lambda do |search_key, offset, limit|
      Kaui::CustomField.list_or_search(search_key, offset, limit, options_for_klient)
    end

    data_extractor = lambda do |custom_field, column|
      [
          custom_field.object_id,
          custom_field.object_type,
          custom_field.name,
          custom_field.value
      ][column]
    end

    formatter = lambda do |custom_field|
      url_for_object = view_context.url_for_object(custom_field.object_id, custom_field.object_type)
      [
          url_for_object ? view_context.link_to(custom_field.object_id, url_for_object) : custom_field.object_id,
          custom_field.object_type,
          custom_field.name,
          custom_field.value
      ]
    end

    paginate searcher, data_extractor, formatter
  end

  def new
    @custom_field = Kaui::CustomField.new
    cf_url = custom_fields_check_object_exist_path

    gon.url = "#{cf_url}"
  end

  def check_object_exist

    param_uuid = params[:uuid]

    # to-do
    # begin
    #   test_uuid = Kaui::InvoiceItem.new(:invoice_item_id => param_uuid)
    #   ap test_uuid and return
    # rescue StandardError
    # ensure
    #   if !test_uuid.blank? && (test_uuid.invoice_item_id == param_uuid)
    #     msg = { status: '200', message: 'UUID do exist in INVOICE ITEMS object database.' }
    #     render json: msg and return
    #   end
    # end

    begin
      test_uuid = Kaui::Account.find_by_id_or_key(param_uuid, false, false, options_for_klient)
    rescue StandardError
    ensure
      if !test_uuid.blank? && (test_uuid.account_id == param_uuid)
        msg = { status: '200', message: 'UUID do exist in ACCOUNT object database.' }
        render json: msg and return
      end
    end

    begin
      test_uuid = Kaui::Bundle.find_by_id_or_key(param_uuid, options_for_klient)
    rescue StandardError
    ensure
      if !test_uuid.blank? && (test_uuid.bundle_id == param_uuid)
        msg = { status: '200', message: 'UUID do exist in BUNDLE object database.' }
        render json: msg and return
      end
    end

    begin
      test_uuid = Kaui::Subscription.find_by_id(param_uuid, options_for_klient)
    rescue StandardError
    ensure
      if !test_uuid.blank? && (test_uuid.subscription_id == param_uuid)
        msg = { status: '200', message: 'UUID do exist in SUBSCRIPCTION object database.' }
        render json: msg and return
      end
    end

    begin
      cached_options_for_klient = options_for_klient
      test_uuid = Kaui::Invoice.find_by_id(param_uuid, 'FULL', cached_options_for_klient)
    rescue StandardError
    ensure
      if !test_uuid.blank? && (test_uuid.invoice_id == param_uuid)
        msg = { status: '200', message: 'UUID do exist in INVOICE object database.' }
        render json: msg and return
      end
    end

    begin
      test_uuid = Kaui::Payment.find_by_external_key(param_uuid, false, true, options_for_klient)
    rescue StandardError
    ensure
      if !test_uuid.blank? && (test_uuid.payment_id == param_uuid)
        msg = { status: '200', message: 'UUID do exist in PAYMENT object database.' }
        render json: msg and return
      end
    end

    begin
      test_uuid = Kaui::InvoicePayment.find_by_id(param_uuid, false, true, options_for_klient)
    rescue StandardError
    ensure
      if !test_uuid.blank? && (test_uuid.payment_id == param_uuid)
        msg = { status: '200', message: 'UUID do exist in INVOICE PAYMENT object database.' }
        render json: msg and return
      end
    end



    msg = { status: '431', message: 'UUID do not  exist in  object database.' }
    render json: msg and return

  end


  def create
    @custom_field = Kaui::CustomField.new(params.require(:custom_field))

    model = case @custom_field.object_type.to_sym
              when :ACCOUNT
                Kaui::Account.new(:account_id => @custom_field.object_id)
              when :BUNDLE
                Kaui::Bundle.new(:bundle_id => @custom_field.object_id)
              when :SUBSCRIPTION
                Kaui::Subscription.new(:subscription_id => @custom_field.object_id)
              when :INVOICE
                Kaui::Invoice.new(:invoice_id => @custom_field.object_id)
              when :PAYMENT
                Kaui::Payment.new(:payment_id => @custom_field.object_id)
              when :INVOICE_ITEM
                Kaui::InvoiceItem.new(:invoice_item_id => @custom_field.object_id)
              else
                flash.now[:error] = "Invalid object type #{@custom_field.object_type}"
                render :new and return
            end
    model.add_custom_field(@custom_field, current_user.kb_username, params[:reason], params[:comment], options_for_klient)

    redirect_to custom_fields_path, :notice => 'Custom field was successfully created'
  end

end
