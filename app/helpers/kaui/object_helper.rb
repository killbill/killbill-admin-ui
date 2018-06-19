module Kaui
  module ObjectHelper

    # Because we don't have access to the account_id, we use the restful_show routes
    def url_for_object(object_id, object_type)
      if object_type == 'ACCOUNT'
        account_path(object_id)
      elsif object_type == 'BUNDLE'
        bundle_path(object_id)
      elsif object_type == 'SUBSCRIPTION'
        subscription_path(object_id)
      elsif object_type == 'INVOICE'
        invoice_path(object_id)
      elsif object_type == 'PAYMENT'
        payment_path(object_id)
      elsif object_type == 'PAYMENT_METHOD'
        payment_method_path(object_id)
      else
        nil
      end
    end

    def object_types
      [:ACCOUNT, :BUNDLE, :INVOICE, :INVOICE_ITEM, :INVOICE_PAYMENT, :PAYMENT, :SUBSCRIPTION, :TRANSACTION]
    end

    def object_types_for_advanced_search
      [:ACCOUNT, :BUNDLE, :INVOICE, :CREDIT, :CUSTOM_FIELD, :INVOICE_PAYMENT, :INVOICE, :PAYMENT, :SUBSCRIPTION, :TRANSACTION, :TAG, :TAG_DEFINITION]
    end

  end
end
