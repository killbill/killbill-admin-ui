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

  end
end
