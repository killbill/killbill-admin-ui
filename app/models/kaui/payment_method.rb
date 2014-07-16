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
end
