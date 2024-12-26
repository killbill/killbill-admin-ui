# frozen_string_literal: true

require 'csv'

module Kaui
  class AuditLogsController < Kaui::EngineController
    OBJECT_WITH_HISTORY = %w[ACCOUNT ACCOUNT_EMAIL BLOCKING_STATES BUNDLE CUSTOM_FIELD INVOICE INVOICE_ITEM PAYMENT_ATTEMPT PAYMENT PAYMENT_METHOD SUBSCRIPTION SUBSCRIPTION_EVENT TRANSACTION TAG TAG_DEFINITION].freeze

    def index
      cached_options_for_klient = options_for_klient
      @account = Kaui::Account.find_by_id_or_key(params.require(:account_id), false, false, cached_options_for_klient)
      audit_logs = @account.audit(cached_options_for_klient)

      formatter = lambda do |log|
        object_id_text = view_context.object_id_popover(log.object_id)

        if object_with_history?(log.object_type)
          object_id_text = view_context.link_to(object_id_text, '#showHistoryModal',
                                                data: {
                                                  toggle: 'modal',
                                                  object_id: log.object_id,
                                                  object_type: log.object_type,
                                                  change_date: log.change_date,
                                                  change_type: log.change_type,
                                                  account_id: @account.account_id
                                                })
        end

        [
          log.change_date,
          object_id_text,
          log.object_type,
          log.change_type,
          log.changed_by,
          log.reason_code,
          log.comments,
          view_context.object_id_popover(log.user_token, 'left')
        ]
      end

      @audit_logs_json = []
      audit_logs.each { |page| @audit_logs_json << formatter.call(page) }

      @audit_logs_json = @audit_logs_json.to_json
    end

    def download
      account_id = params.require(:account_id)
      start_date = params[:startDate]
      end_date = params[:endDate]
      start_date = begin
        Date.parse(start_date)
      rescue StandardError
        nil
      end
      end_date = begin
        Date.parse(end_date)
      rescue StandardError
        nil
      end

      account = Kaui::Account.find_by_id_or_key(account_id, false, false, options_for_klient)
      audit_logs = account.audit(options_for_klient)

      csv_file = CSV.generate do |csv|
        csv << Kaui.account_audit_logs_columns.call[0]
        audit_logs.each do |log|
          change_date = begin
            Date.parse(log.change_date)
          rescue StandardError
            nil
          end
          next if start_date && end_date && change_date && !(change_date > start_date && change_date < end_date)

          csv << [log.change_date, log.object_id, log.object_type, log.change_type, log.changed_by, log.reason_code, log.comments, log.user_token]
        end
      end

      send_data csv_file, type: 'text/csv', filename: "audit-logs-#{Date.today}.csv"
    end

    def history
      json_response do
        account_id = params.require(:account_id)
        object_id = params.require(:object_id)
        object_type = params.require(:object_type)
        cached_options_for_klient = options_for_klient

        audit_logs_with_history = []
        error = nil

        begin
          case object_type
          when 'ACCOUNT'
            account = Kaui::Account.find_by_id_or_key(object_id, false, false, cached_options_for_klient)
            audit_logs_with_history = account.audit_logs_with_history(cached_options_for_klient)
          when 'ACCOUNT_EMAIL'
            account = Kaui::Account.find_by_id_or_key(account_id, false, false, cached_options_for_klient)
            audit_logs_with_history = account.email_audit_logs_with_history(object_id, cached_options_for_klient)
          when 'BLOCKING_STATES'
            audit_logs_with_history = Kaui::Account.blocking_state_audit_logs_with_history(object_id, cached_options_for_klient)
          when 'BUNDLE'
            bundle = Kaui::Bundle.find_by_id(object_id, cached_options_for_klient)
            audit_logs_with_history = bundle.audit_logs_with_history(cached_options_for_klient)
          when 'CUSTOM_FIELD'
            audit_logs_with_history = Kaui::CustomField.new({ custom_field_id: object_id }).audit_logs_with_history(cached_options_for_klient)
          when 'INVOICE'
            invoice = Kaui::Invoice.find_by_id(object_id, false, 'NONE', cached_options_for_klient)
            audit_logs_with_history = invoice.audit_logs_with_history(cached_options_for_klient)
          when 'INVOICE_ITEM'
            invoice_item = Kaui::InvoiceItem.new
            invoice_item.invoice_item_id = object_id
            audit_logs_with_history = invoice_item.audit_logs_with_history(cached_options_for_klient)
          # See https://github.com/killbill/killbill/issues/1104
          #         elsif object_type == 'INVOICE_PAYMENT'
          #           invoice_payment = Kaui::InvoicePayment::find_by_id(object_id, false, false, cached_options_for_klient)
          #           audit_logs_with_history = invoice_payment.audit_logs_with_history(cached_options_for_klient)
          when 'PAYMENT_ATTEMPT'
            audit_logs_with_history = Kaui::Payment.attempt_audit_logs_with_history(object_id, cached_options_for_klient)
          when 'PAYMENT'
            payment = Kaui::Payment.find_by_id(object_id, false, false, cached_options_for_klient)
            audit_logs_with_history = payment.audit_logs_with_history(cached_options_for_klient)
          when 'PAYMENT_METHOD'
            payment_method = Kaui::PaymentMethod.find_by_id(object_id, false, false, [], 'NONE', cached_options_for_klient)
            audit_logs_with_history = payment_method.audit_logs_with_history(cached_options_for_klient)
          when 'SUBSCRIPTION'
            subscription = Kaui::Subscription.find_by_id(object_id, 'NONE', cached_options_for_klient)
            audit_logs_with_history = subscription.audit_logs_with_history(cached_options_for_klient)
          when 'SUBSCRIPTION_EVENT'
            audit_logs_with_history = Kaui::Subscription.event_audit_logs_with_history(object_id, cached_options_for_klient)
          when 'TRANSACTION'
            audit_logs_with_history = Kaui::Transaction.new({ transaction_id: object_id }).audit_logs_with_history(cached_options_for_klient)
          when 'TAG'
            audit_logs_with_history = Kaui::Tag.new({ tag_id: object_id }).audit_logs_with_history(cached_options_for_klient)
          when 'TAG_DEFINITION'
            audit_logs_with_history = Kaui::TagDefinition.new({ id: object_id }).audit_logs_with_history(cached_options_for_klient)
          else
            error = "Object [#{object_type}] history is not supported."
          end
        rescue StandardError => e
          error = e.message
        end

        { audits: audit_logs_with_history, error: }
      end
    end

    private

    def object_with_history?(object_type)
      return false if object_type.nil?

      OBJECT_WITH_HISTORY.include?(object_type)
    end
  end
end
