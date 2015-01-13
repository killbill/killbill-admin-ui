class Kaui::PaymentMethod < KillBillClient::Model::PaymentMethod

  def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
    if search_key.present?
      find_in_batches_by_search_key(search_key, offset, limit, options)
    else
      find_in_batches(offset, limit, options)
    end
  end

  def self.find_non_external_by_account_id(account_id, with_plugin_info = false, options = {})
    payment_methods = find_all_by_account_id(account_id, with_plugin_info, options)
    payment_methods.reject { |x| x.plugin_name == '__EXTERNAL_PAYMENT__' }
  end

  def self.payment_methods_for_payments(payments = [], options = {})
    payment_method_per_payment = {}
    payment_methods_cache      = {}
    deleted_payment_methods    = Set.new

    payments.each do |payment|
      next if deleted_payment_methods.include?(payment.payment_method_id)

      # The payment method may have been deleted
      payment_methods_cache[payment.payment_method_id] ||= Kaui::PaymentMethod.find_by_id(payment.payment_method_id, true, options) rescue nil

      if payment_methods_cache[payment.payment_method_id].nil?
        deleted_payment_methods.add(payment.payment_method_id)
      else
        payment_method_per_payment[payment.payment_id] = payment_methods_cache[payment.payment_method_id]
      end
    end

    payment_method_per_payment
  end
end
