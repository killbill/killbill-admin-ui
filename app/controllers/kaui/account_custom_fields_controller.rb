# frozen_string_literal: true

module Kaui
  class AccountCustomFieldsController < Kaui::EngineController
    def index
      cached_options_for_klient = options_for_klient
      account = Kaui::Account.find_by_id_or_key(params.require(:account_id), true, true, cached_options_for_klient)
      custom_fields = account.all_custom_fields(nil, 'NONE', cached_options_for_klient)

      formatter = lambda do |custom_field|
        url_for_object = view_context.url_for_object(custom_field.object_id, custom_field.object_type)
        [
          url_for_object ? view_context.link_to(custom_field.object_id, url_for_object) : custom_field.object_id,
          custom_field.object_type,
          custom_field.name,
          custom_field.value
        ]
      end
      @custom_fields_json = []
      custom_fields.each { |page| @custom_fields_json << formatter.call(page) }

      @custom_fields_json = @custom_fields_json.to_json
    end
  end
end
