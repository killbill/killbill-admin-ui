# frozen_string_literal: true

require 'csv'

module Kaui
  class PaymentsController < Kaui::EngineController
    def index
      @search_query = params[:q] || params[:account_id]

      @ordering = params[:ordering] || (@search_query.blank? ? 'desc' : 'asc')
      @offset = params[:offset] || 0
      @limit = params[:limit] || 50

      @max_nb_records = @search_query.blank? ? Kaui::Payment.list_or_search(nil, 0, 0, options_for_klient).pagination_max_nb_records : 0
    end

    def download
      account_id = params[:account_id]
      start_date = params[:startDate]
      end_date = params[:endDate]
      all_fields_checked = params[:allFieldsChecked] == 'true'
      if all_fields_checked
        columns = KillBillClient::Model::PaymentAttributes.instance_variable_get('@json_attributes') - %w[transactions audit_logs]
      else
        columns = params.require(:columnsString).split(',').map { |attr| attr.split.join('_').downcase }
        Kaui::Payment::REMAPPING_FIELDS.each do |k, v|
          index = columns.index(v)
          columns[index] = k if index
        end
      end

      kb_params = {}
      kb_params[:startDate] = Date.parse(start_date).strftime('%Y-%m-%d') if start_date
      kb_params[:endDate] = Date.parse(end_date).strftime('%Y-%m-%d') if end_date
      if account_id.present?
        account = Kaui::Account.find_by_id_or_key(account_id, false, false, options_for_klient)
        payments = account.payments(options_for_klient).map! { |payment| Kaui::Payment.build_from_raw_payment(payment) }
      else
        payments = Kaui::Payment.list_or_search(nil, 0, MAXIMUM_NUMBER_OF_RECORDS_DOWNLOAD, options_for_klient.merge(params: kb_params))
      end

      payments.each do |payment|
        created_date = nil
        payment.transactions.each do |transaction|
          transaction_date = Date.parse(transaction.effective_date)
          created_date = transaction_date if created_date.nil? || (transaction_date < created_date)
        end
        payment.payment_date = created_date
      end

      csv_string = CSV.generate(headers: true) do |csv|
        csv << columns

        payments.each do |payment|
          next if start_date && end_date && (payment.payment_date < Date.parse(start_date) || payment.payment_date > Date.parse(end_date))

          data = columns.map do |attr|
            case attr
            when 'payment_number'
              payment.payment_number
            when 'payment_date'
              view_context.format_date(payment.payment_date, account&.time_zone)
            when 'total_authed_amount_to_money'
              view_context.humanized_money_with_symbol(payment.total_authed_amount_to_money)
            when 'paid_amount_to_money'
              view_context.humanized_money_with_symbol(payment.paid_amount_to_money)
            when 'returned_amount_to_money'
              view_context.humanized_money_with_symbol(payment.returned_amount_to_money)
            when 'status'
              payment.transactions.empty? ? nil : payment.transactions[-1].status
            else
              payment&.send(attr.downcase)
            end
          end
          csv << data
        end
      end
      send_data csv_string, filename: "payments-#{Date.today}.csv", type: 'text/csv'
    end

    def pagination
      account = nil
      searcher = lambda do |search_key, offset, limit|
        if Kaui::Payment::TRANSACTION_STATUSES.include?(search_key)
          # Search is done by payment state on the server side, see http://docs.killbill.io/latest/userguide_payment.html#_payment_states
          payment_state = if %w[PLUGIN_FAILURE UNKNOWN].include?(search_key)
                            '_ERRORED'
                          elsif search_key == 'PAYMENT_FAILURE'
                            '_FAILED'
                          else
                            "_#{search_key}"
                          end
          payments = Kaui::Payment.list_or_search(payment_state, offset, limit, options_for_klient)
        else
          account = begin
            Kaui::Account.find_by_id_or_key(search_key, false, false, options_for_klient)
          rescue StandardError
            nil
          end

          payments = if account.nil?
                       Kaui::Payment.list_or_search(search_key, offset, limit, options_for_klient)
                     else
                       account.payments(options_for_klient).map! { |payment| Kaui::Payment.build_from_raw_payment(payment) }
                     end
        end

        payments.each do |payment|
          created_date = nil
          payment.transactions.each do |transaction|
            transaction_date = Date.parse(transaction.effective_date)
            created_date = transaction_date if created_date.nil? || (transaction_date < created_date)
          end
          payment.payment_date = created_date
        end

        payments
      end

      data_extractor = lambda do |payment, column|
        Kaui.account_payments_columns.call(account, payment, view_context)[2][column]
      end

      formatter = lambda do |payment|
        Kaui.account_payments_columns.call(account, payment, view_context)[1]
      end

      paginate searcher, data_extractor, formatter
    end

    def new
      cached_options_for_klient = options_for_klient
      fetch_invoice = promise { Kaui::Invoice.find_by_id(params.require(:invoice_id), false, 'NONE', cached_options_for_klient) }
      fetch_payment_methods = promise { Kaui::PaymentMethod.find_all_by_account_id(params.require(:account_id), false, cached_options_for_klient) }

      @invoice = wait(fetch_invoice)
      @payment_methods = wait(fetch_payment_methods)

      @payment = Kaui::InvoicePayment.new('accountId' => @account.account_id, 'targetInvoiceId' => @invoice.invoice_id, 'purchasedAmount' => @invoice.balance)
    end

    def create
      payment = Kaui::InvoicePayment.new(invoice_payment_params)
      external_payment = params[:external] == '1'
      payment.payment_method_id = nil if external_payment || payment.payment_method_id.blank?
      payment.create(external_payment, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.account_invoice_path(payment.account_id, payment.target_invoice_id), notice: 'Payment triggered'
    end

    def show
      cached_options_for_klient = options_for_klient

      invoice_payment = Kaui::InvoicePayment.find_safely_by_id(params.require(:id), cached_options_for_klient)
      @payment = Kaui::InvoicePayment.build_from_raw_payment(invoice_payment)

      fetch_payment_fields = promise do
        direct_payment = Kaui::Payment.new(payment_id: @payment.payment_id)
        direct_payment.custom_fields('NONE', cached_options_for_klient).sort { |cf_a, cf_b| cf_a.name.downcase <=> cf_b.name.downcase }
      end
      # The payment method may have been deleted
      fetch_payment_method = promise { Kaui::PaymentMethod.find_safely_by_id(@payment.payment_method_id, cached_options_for_klient) }

      @custom_fields = wait(fetch_payment_fields)
      @payment_method = wait(fetch_payment_method)
    end

    def restful_show
      begin
        payment = Kaui::InvoicePayment.find_by_id(params.require(:id), false, true, options_for_klient)
      rescue KillBillClient::API::NotFound
        payment = Kaui::Payment.find_by_external_key(params.require(:id), false, true, options_for_klient)
      end
      redirect_to account_payment_path(payment.account_id, payment.payment_id)
    end

    def cancel_scheduled_payment
      payment_transaction = Kaui::Transaction.new
      payment_transaction.transaction_external_key = params.require(:transaction_external_key)

      payment_transaction.cancel_scheduled_payment(current_user.kb_username, params[:reason], params[:comment], options_for_klient)

      redirect_to kaui_engine.account_payment_path(params.require(:account_id), params.require(:id)), notice: 'Payment attempt retry successfully deleted'
    rescue StandardError => e
      flash[:error] = "Error deleting payment attempt retry: #{as_string(e)}"
      redirect_to kaui_engine.account_path(params.require(:account_id))
    end

    private

    def invoice_payment_params
      invoice_payment = params.require(:invoice_payment)
      invoice_payment.require(:target_invoice_id)
      invoice_payment
    end
  end
end
