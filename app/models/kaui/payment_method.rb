# frozen_string_literal: true

module Kaui
  class PaymentMethod < KillBillClient::Model::PaymentMethod
    def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
      if search_key.present?
        find_in_batches_by_search_key(search_key, offset, limit, options)
      else
        find_in_batches(offset, limit, options)
      end
    end

    def self.find_safely_by_id(id, options = {})
      Kaui::PaymentMethod.find_by_id(id, true, options)
    rescue StandardError => e
      # Maybe the plugin is not registered or the plugin threw an exception
      Rails.logger.warn(e)
      begin
        Kaui::PaymentMethod.find_by_id(id, false, options)
      rescue StandardError
        nil
      end
    end

    def self.find_all_safely_by_account_id(account_id, options = {})
      pms = Kaui::PaymentMethod.find_all_by_account_id(account_id, false, options)

      pms.each_with_index do |pm, i|
        pms[i] = Kaui::PaymentMethod.find_by_id(pm.payment_method_id, true, options)
      rescue StandardError => e
        # Maybe the plugin is not registered or the plugin threw an exception
        Rails.logger.warn(e)
      end
      pms
    end

    def self.find_non_external_by_account_id(account_id, with_plugin_info, options = {})
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
        payment_methods_cache[payment.payment_method_id] ||= begin
          Kaui::PaymentMethod.find_by_id(payment.payment_method_id, true, options)
        rescue StandardError
          nil
        end

        if payment_methods_cache[payment.payment_method_id].nil?
          deleted_payment_methods.add(payment.payment_method_id)
        else
          payment_method_per_payment[payment.payment_id] = payment_methods_cache[payment.payment_method_id]
        end
      end

      payment_method_per_payment
    end
  end
end
