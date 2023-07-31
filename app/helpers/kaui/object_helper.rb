# frozen_string_literal: true

module Kaui
  module ObjectHelper
    ADVANCED_SEARCH_OBJECT_FIELDS = %w[ID EXTERNAL_KEY NUMBER].freeze
    ADVANCED_SEARCH_OBJECT_FIELDS_MAP = {
      # ID is supported by all object types, hence not listed.
      EXTERNAL_KEY: %w[ACCOUNT PAYMENT TRANSACTION BUNDLE],
      NUMBER: %w[INVOICE]
    }.freeze

    # Because we don't have access to the account_id, we use the restful_show routes
    def url_for_object(object_id, object_type)
      case object_type
      when 'ACCOUNT'
        account_path(object_id)
      when 'BUNDLE'
        bundle_path(object_id)
      when 'SUBSCRIPTION'
        subscription_path(object_id)
      when 'INVOICE'
        invoice_path(object_id)
      when 'PAYMENT'
        payment_path(object_id)
      when 'PAYMENT_METHOD'
        payment_method_path(object_id)
      else
        nil
      end
    end

    def object_types
      %i[ACCOUNT BUNDLE INVOICE INVOICE_ITEM INVOICE_PAYMENT PAYMENT SUBSCRIPTION TRANSACTION]
    end

    def object_types_for_advanced_search
      %i[ACCOUNT BUNDLE INVOICE CREDIT CUSTOM_FIELD INVOICE_PAYMENT PAYMENT SUBSCRIPTION TRANSACTION TAG TAG_DEFINITION]
    end

    def object_fields_for_advanced_search
      [' '] + ADVANCED_SEARCH_OBJECT_FIELDS
    end

    def advanced_search_object_fields_map
      ADVANCED_SEARCH_OBJECT_FIELDS_MAP
    end
  end
end
