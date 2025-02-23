# frozen_string_literal: true

require 'csv'

module Kaui
  class AccountTimelinesController < Kaui::EngineController
    def show
      timeline = Kaui::AccountTimeline.find_by_account_id(params.require(:account_id), 'FULL', options_for_klient)
      @account = timeline.account
      @bundles = timeline.bundles
      @invoices = timeline.invoices
      @payments = timeline.payments
      extract_invoices_by_id(@invoices)

      # Lookup all bundle names
      @bundle_names = {}
      @bundle_names_by_invoice_id = {}
      @bundle_keys_by_invoice_id = {}
      @bundles.each do |bundle|
        load_bundle_name_for_timeline(bundle.external_key)
      end
      @invoices.each do |invoice|
        @bundle_names_by_invoice_id[invoice.invoice_id] = Set.new
        @bundle_keys_by_invoice_id[invoice.invoice_id] = Set.new
        (invoice.bundle_keys || '').split(',').each do |bundle_key|
          load_bundle_name_for_timeline(bundle_key)
          @bundle_names_by_invoice_id[invoice.invoice_id] << @bundle_names[bundle_key]
          @bundle_keys_by_invoice_id[invoice.invoice_id] << bundle_key
        end
      end

      @selected_bundle = params.key?(:external_key) ? @bundle_names[params[:external_key]] : nil
    end

    def download
      timeline = Kaui::AccountTimeline.find_by_account_id(params.require(:account_id), 'FULL', options_for_klient)
      start_date = begin
        Date.parse(params[:startDate])
      rescue StandardError
        nil
      end
      end_date = begin
        Date.parse(params[:endDate])
      rescue StandardError
        nil
      end

      event_type = params[:eventType]
      @account = timeline.account
      @bundles = timeline.bundles
      @invoices = timeline.invoices
      @payments = timeline.payments
      extract_invoices_by_id(@invoices)

      # Lookup all bundle names
      @bundle_names = {}
      @bundle_names_by_invoice_id = {}
      @bundle_keys_by_invoice_id = {}
      @bundles.each do |bundle|
        load_bundle_name_for_timeline(bundle.external_key)
      end
      @invoices.each do |invoice|
        @bundle_names_by_invoice_id[invoice.invoice_id] = Set.new
        @bundle_keys_by_invoice_id[invoice.invoice_id] = Set.new
        (invoice.bundle_keys || '').split(',').each do |bundle_key|
          load_bundle_name_for_timeline(bundle_key)
          @bundle_names_by_invoice_id[invoice.invoice_id] << @bundle_names[bundle_key]
          @bundle_keys_by_invoice_id[invoice.invoice_id] << bundle_key
        end
      end

      @selected_bundle = params.key?(:external_key) ? @bundle_names[params[:external_key]] : nil

      csv_string = CSV.generate(headers: true) do |csv|
        csv << ['Effective Date', 'Bundles', 'Even Type', 'Details', 'Reason Code/ Comments']
        if %w[INVOICE ALL].include?(event_type)
          @invoices.each do |invoice_stub|
            invoice = invoice_stub.invoice_id.present? && @invoices_by_id.key?(invoice_stub.invoice_id) ? @invoices_by_id[invoice_stub.invoice_id] : invoice_stub
            target_date = invoice.target_date.present? ? invoice.target_date : '[unknown]'
            bundle_keys = invoice_stub.bundle_keys.present? ? invoice_stub.bundle_keys.split(',').map { |bundle_key| @bundle_names[bundle_key] }.join(', ') : ''
            invoice_details = []
            invoice_details << "Amount: #{invoice.amount_to_money} (#{@account.currency})"
            invoice_details << "Balance: #{invoice.balance_to_money} (#{@account.currency})"
            invoice_details << "Credit adjustment: #{invoice.credit_adjustment_to_money} (#{@account.currency})" if invoice.credit_adj.present? && invoice.credit_adj.positive?
            invoice_details << "Refund adjustment: #{invoice.refund_adjustment_to_money} (#{@account.currency})" if invoice.refund_adj.present? && invoice.refund_adj.negative?
            invoice_details << "Invoice #: #{invoice.invoice_number}"
            audit_logs = invoice_stub.audit_logs.present? ? invoice_stub.audit_logs.map { |entry| Kaui::AuditLog.description(entry) }.join(', ') : ''
            csv << [target_date, bundle_keys, 'INVOICE', invoice_details.join('; '), audit_logs] if filter_date(target_date, start_date, end_date)
          end
        end
        if %w[PAYMENT ALL].include?(event_type)
          @payments.each do |payment|
            invoice = if payment.target_invoice_id.present?
                        @invoices_by_id[payment.target_invoice_id]
                      else
                        nil
                      end

            payment.transactions.each do |transaction|
              effective_date = transaction.effective_date.present? ? transaction.effective_date : '[unknown]'
              bundle_keys = @bundle_keys_by_invoice_id[payment.target_invoice_id].present? ? @bundle_keys_by_invoice_id[payment.target_invoice_id].map { |bundle_key| @bundle_names[bundle_key] }.join(', ') : ''
              transaction_type = transaction.transaction_type
              details = []
              details << "Amount: #{Kaui::Transaction.amount_to_money(transaction)} (#{transaction.currency})" unless transaction.transaction_type == 'VOID'
              details << "Status: #{transaction.status}"
              details << "Payment #: #{payment.payment_number}"
              details << "Invoice #: #{invoice.invoice_number}" unless invoice.nil?

              audit_logs = transaction.audit_logs.present? ? transaction.audit_logs.map { |entry| Kaui::AuditLog.description(entry) }.chunk { |x| x }.map(&:first).join(', ') : ''

              csv << [effective_date, bundle_keys, transaction_type, details.join('; '), audit_logs] if filter_date(effective_date, start_date, end_date)
            end
          end
        end

        if %w[ENTITLEMENT ALL].include?(event_type)
          @bundles.each do |bundle|
            bundle.subscriptions.each do |sub|
              sub.events.each do |event|
                # Skip SERVICE_STATE_CHANGE events
                next if event.event_type == 'SERVICE_STATE_CHANGE'

                effective_date = event.effective_date.present? ? event.effective_date : '[unknown]'
                bundle_keys = @bundle_names[bundle.external_key]
                event_type = event.event_type
                phase = event.phase
                audit_logs = event.audit_logs.present? ? event.audit_logs.map { |entry| Kaui::AuditLog.description(entry) }.join(', ') : ''

                csv << [effective_date, bundle_keys, event_type, phase, audit_logs] if filter_date(effective_date, start_date, end_date)
              end
            end
          end
        end
      end

      send_data csv_string, filename: "account-timelines-#{Date.today}.csv", type: 'text/csv'
    end

    private

    def filter_date(target_date, start_date, end_date)
      return true if start_date.nil? || end_date.nil?

      target_date = begin
        Date.parse(target_date)
      rescue StandardError
        nil
      end
      target_date >= start_date && target_date <= end_date
    end

    def load_bundle_name_for_timeline(bundle_key)
      @bundle_names[bundle_key] ||= Kaui.bundle_key_display_string.call(bundle_key)
    end

    def extract_invoices_by_id(all_invoices)
      return {} if all_invoices.nil? || all_invoices.empty?

      # Convert into Kaui::Invoice to benefit from additional methods xxx_to_money
      @invoices_by_id = all_invoices.each_with_object({}) do |invoice, hsh|
        hsh[invoice.invoice_id] = Kaui::Invoice.build_from_raw_invoice(invoice)
      end
    end
  end
end
