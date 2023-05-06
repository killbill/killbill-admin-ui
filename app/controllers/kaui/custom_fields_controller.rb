# frozen_string_literal: true

module Kaui
  class CustomFieldsController < Kaui::EngineController
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

    def check_object_exist
      param_uuid = params[:uuid]
      param_object_type = params[:object_type]

      _check_object_exist(param_uuid, param_object_type)
    end

    def create
      @custom_field = Kaui::CustomField.new(params.require(:custom_field))

      param_uuid = @custom_field.object_id

      test_uuid = nil
      case @custom_field.object_type.to_sym
      when :ACCOUNT
        begin
          test_uuid = Kaui::Account.find_by_id_or_key(param_uuid, false, false, options_for_klient)
        rescue StandardError
          # Ignore
        end
      when :BUNDLE
        begin
          test_uuid = Kaui::Bundle.find_by_id_or_key(param_uuid, options_for_klient)
        rescue StandardError
          # Ignore
        end
      when :SUBSCRIPTION
        begin
          test_uuid = Kaui::Subscription.find_by_id(param_uuid, options_for_klient)
        rescue StandardError
          # Ignore
        end
      when :INVOICE
        begin
          test_uuid = Kaui::Invoice.find_by_id(param_uuid, false, 'NONE', options_for_klient)
        rescue StandardError
          # Ignore
        end
      when :PAYMENT
        begin
          test_uuid = Kaui::InvoicePayment.find_by_id(param_uuid, false, true, options_for_klient)
        rescue StandardError
          # Ignore
        end
        begin
          test_uuid = Kaui::Payment.find_by_external_key(param_uuid, false, true, options_for_klient)
        rescue StandardError
          # Ignore
        end
      when :INVOICE_ITEM
        begin
          test_uuid = Kaui::Invoice.find_by_invoice_item_id(param_uuid, false, 'NONE', options_for_klient)
        rescue StandardError
          # Ignore
        end
      end

      if test_uuid.blank?
        flash[:error] = I18n.translate('object_invalid_dont_exist')
        redirect_to custom_fields_path
        return
      end

      model = case @custom_field.object_type.to_sym
              when :ACCOUNT
                Kaui::Account.new(account_id: @custom_field.object_id)
              when :BUNDLE
                Kaui::Bundle.new(bundle_id: @custom_field.object_id)
              when :SUBSCRIPTION
                Kaui::Subscription.new(subscription_id: @custom_field.object_id)
              when :INVOICE
                Kaui::Invoice.new(invoice_id: @custom_field.object_id)
              when :PAYMENT
                Kaui::Payment.new(payment_id: @custom_field.object_id)
              when :INVOICE_ITEM
                Kaui::InvoiceItem.new(invoice_item_id: @custom_field.object_id)
              else
                flash.now[:error] = I18n.translate('invalid_object_type', error: @custom_field.object_type)
                render :new and return
              end
      model.add_custom_field(@custom_field, current_user.kb_username, params[:reason], params[:comment], options_for_klient)

      redirect_to custom_fields_path, notice: I18n.translate('custom_field_created_success')
    end

    private

    def _check_object_exist(uuid, object_type)
      param_uuid = uuid
      param_object_type = object_type

      test_uuid = nil
      msg = nil
      case param_object_type
      when  'INVOICE_ITEM'
        begin
          test_uuid = Kaui::Invoice.find_by_invoice_item_id(param_uuid, false, 'NONE', options_for_klient)
        rescue StandardError
          # Ignore
        ensure
          msg = { status: '200', message: I18n.translate('custom_field_uuid_exist_in_invoice_item_db') } unless test_uuid.blank?
        end
      when  'ACCOUNT'
        begin
          test_uuid = Kaui::Account.find_by_id_or_key(param_uuid, false, false, options_for_klient)
        rescue StandardError
          # Ignore
        ensure
          msg = { status: '200', message: I18n.translate('custom_field_uuid_exist_in_account_db') } if !test_uuid.blank? && (test_uuid.account_id == param_uuid)
        end
      when  'BUNDLE'
        begin
          test_uuid = Kaui::Bundle.find_by_id_or_key(param_uuid, options_for_klient)
        rescue StandardError
          # Ignore
        ensure
          msg = { status: '200', message: I18n.translate('custom_field_uuid_exist_in_bundle_db') } if !test_uuid.blank? && (test_uuid.bundle_id == param_uuid)
        end
      when  'SUBSCRIPTION'
        begin
          test_uuid = Kaui::Subscription.find_by_id(param_uuid, options_for_klient)
        rescue StandardError
          # Ignore
        ensure
          msg = { status: '200', message: I18n.translate('custom_field_uuid_exist_in_subscription_db') } if !test_uuid.blank? && (test_uuid.subscription_id == param_uuid)
        end
      when  'INVOICE'
        begin
          cached_options_for_klient = options_for_klient
          test_uuid = Kaui::Invoice.find_by_id(param_uuid, 'FULL', cached_options_for_klient)
        rescue StandardError
          # Ignore
        ensure
          msg = { status: '200', message: I18n.translate('custom_field_uuid_exist_in_invoice_db') } if !test_uuid.blank? && (test_uuid.invoice_id == param_uuid)
        end
      when  'PAYMENT'
        begin
          test_uuid = Kaui::InvoicePayment.find_by_id(param_uuid, false, true, options_for_klient)
        rescue StandardError
          # Ignore
        ensure
          msg = { status: '200', message: I18n.translate('custom_field_uuid_exist_in_invoice_payment_db') } if !test_uuid.blank? && (test_uuid.payment_id == param_uuid)
        end
        begin
          test_uuid = Kaui::Payment.find_by_external_key(param_uuid, false, true, options_for_klient)
        rescue StandardError
          # Ignore
        ensure
          msg = { status: '200', message: I18n.translate('custom_field_uuid_exist_in_payment_db') } if !test_uuid.blank? && (test_uuid.payment_id == param_uuid)
        end
      end

      msg ||= { status: '431', message: I18n.translate('custom_field_uuid_do_not_exist_in_db') }
      render json: msg
    end
  end
end
