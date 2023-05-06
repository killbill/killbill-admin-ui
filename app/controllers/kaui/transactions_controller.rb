# frozen_string_literal: true

module Kaui
  class TransactionsController < Kaui::EngineController
    def restful_show
      payment = Kaui::Payment.find_by_transaction_id(params.require(:id), false, true, options_for_klient)
      redirect_to account_payment_path(payment.account_id, payment.payment_id)
    end

    def new
      @account_id = params[:account_id]
      @payment_method_id = params[:payment_method_id]

      transaction_id = params[:transaction_id].presence
      if transaction_id.nil?
        @transaction = Kaui::Transaction.new(payment_id: params[:payment_id],
                                             amount: params[:amount],
                                             currency: params[:currency],
                                             transaction_type: params[:transaction_type])
      else
        payment = Kaui::Payment.find_by_transaction_id(transaction_id, false, false, options_for_klient)
        @transaction = Kaui::Transaction.build_from_raw_transaction(payment.transactions.find { |tx| tx.transaction_id == transaction_id })
      end
    end

    def create
      transaction = Kaui::Transaction.new(params[:transaction].delete_if { |_key, value| value.blank? })

      plugin_properties = params[:plugin_properties].values.reject { |item| (item['value'].blank? || item['key'].blank?) } unless params[:plugin_properties].blank?
      unless plugin_properties.blank?
        plugin_properties.map! do |property|
          KillBillClient::Model::PluginPropertyAttributes.new(property)
        end
      end

      options = plugin_properties.blank? ? options_for_klient : { pluginProperty: plugin_properties }.merge(options_for_klient)

      control_plugin_names = params[:control_plugin_names].reject(&:blank?) unless params[:control_plugin_names].blank?
      options.merge!({ controlPluginNames: control_plugin_names }) unless control_plugin_names.blank?

      payment = transaction.create(params.require(:account_id), params[:payment_method_id], current_user.kb_username, params[:reason], params[:comment], options)
      redirect_to kaui_engine.account_payment_path(payment.account_id, payment.payment_id), notice: 'Transaction successfully created'
    end

    def fix_transaction_state
      transaction = Kaui::Transaction.new(params[:transaction].delete_if { |_key, value| value.blank? })
      payment_id = transaction.payment_id
      transaction_id = transaction.transaction_id
      transaction_status = transaction.status

      Kaui::Admin.fix_transaction_state(payment_id, transaction_id, transaction_status, current_user.kb_username, params[:reason], params[:comment], options_for_klient)

      redirect_to kaui_engine.account_payment_path(params.require(:account_id), payment_id), notice: "Transaction successfully transitioned to #{transaction_status}"
    end
  end
end
