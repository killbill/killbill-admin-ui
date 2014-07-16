class Kaui::PaymentMethod < KillBillClient::Model::PaymentMethod

  def self.find_non_external_by_account_id(account_id, with_plugin_info = false, options = {})
    payment_methods = find_all_by_account_id(account_id, with_plugin_info, options)
    payment_methods.reject { |x| x.plugin_name == '__EXTERNAL_PAYMENT__' }
  end
end
