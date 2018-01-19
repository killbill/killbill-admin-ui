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
