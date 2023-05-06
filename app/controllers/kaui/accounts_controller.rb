# frozen_string_literal: true

module Kaui
  class AccountsController < Kaui::EngineController
    def index
      @search_query = params[:q]

      if params[:fast] == '1' && !@search_query.blank?
        account = Kaui::Account.list_or_search(@search_query, -1, 1, options_for_klient).first
        if account.nil?
          flash[:error] = "No account matches \"#{@search_query}\""
          redirect_to kaui_engine.home_path
        else
          redirect_to kaui_engine.account_path(account.account_id)
        end
        return
      end

      @ordering = params[:ordering] || (@search_query.blank? ? 'desc' : 'asc')
      @offset = params[:offset] || 0
      @limit = params[:limit] || 50

      @max_nb_records = @search_query.blank? ? Kaui::Account.list_or_search(nil, 0, 0, options_for_klient).pagination_max_nb_records : 0
    end

    def pagination
      cached_options_for_klient = options_for_klient
      searcher = lambda do |search_key, offset, limit|
        Kaui::Account.list_or_search(search_key, offset, limit, cached_options_for_klient)
      end

      data_extractor = lambda do |account, column|
        [
          account.parent_account_id,
          account.account_id,
          account.external_key,
          account.account_balance
        ][column]
      end

      formatter = lambda do |account|
        child_label = ''
        unless account.parent_account_id.nil?
          child_label = account.parent_account_id.nil? ? '' : view_context.content_tag(:span, 'Child', class: %w[label label-info account-child-label])
        end

        row = [child_label, view_context.link_to(account.account_id, view_context.url_for(action: :show, account_id: account.account_id))]
        row += Kaui.account_search_columns.call(account, view_context)[1]
        row
      end

      paginate searcher, data_extractor, formatter
    end

    def new
      @account = Kaui::Account.new
    end

    def create
      @account = Kaui::Account.new(params.require(:account).delete_if { |_key, value| value.blank? })

      @account.errors.add(:phone, :invalid_phone) if !@account.phone.nil? && !@account.check_account_details_phone

      @account.errors.add(:check_account_details_bill_cycle_day_local, :invalid_bill_cycle_day_local) if !@account.bill_cycle_day_local.nil? && !@account.check_account_details_bill_cycle_day_local

      unless @account.errors.empty?
        flash.now[:errors] = @account.errors.messages.values.flatten
        render action: :new and return
      end

      # Transform "1" into boolean
      @account.is_migrated = @account.is_migrated == '1'

      begin
        @account = @account.create(current_user.kb_username, params[:reason], params[:comment], options_for_klient)

        redirect_to account_path(@account.account_id), notice: 'Account was successfully created'
      rescue StandardError => e
        flash.now[:error] = "Error while creating account: #{as_string(e)}"
        render action: :new
      end
    end

    # rubocop:disable Style/MultilineBlockChain
    def show
      # Go to the database once
      cached_options_for_klient = options_for_klient

      # Re-fetch the account with balance and CBA
      @account = Kaui::Account.find_by_id_or_key(params.require(:account_id), true, true, cached_options_for_klient)

      fetch_children = promise { @account.children(false, false, 'NONE', cached_options_for_klient) }
      fetch_parent = @account.parent_account_id.nil? ? nil : promise { Kaui::Account.find_by_id(@account.parent_account_id, false, false, cached_options_for_klient) }
      fetch_overdue_state = promise { @account.overdue(cached_options_for_klient) }
      fetch_account_tags = promise { @account.tags(false, 'NONE', cached_options_for_klient).sort { |tag_a, tag_b| tag_a <=> tag_b } }
      fetch_account_fields = promise { @account.custom_fields('NONE', cached_options_for_klient).sort { |cf_a, cf_b| cf_a.name.downcase <=> cf_b.name.downcase } }
      fetch_account_emails = promise { Kaui::AccountEmail.find_all_sorted_by_account_id(@account.account_id, 'NONE', cached_options_for_klient) }
      fetch_payments = promise { @account.payments(cached_options_for_klient).map! { |payment| Kaui::Payment.build_from_raw_payment(payment) } }
      fetch_payment_methods = promise { Kaui::PaymentMethod.find_all_by_account_id(@account.account_id, false, cached_options_for_klient) }

      # is email notification plugin available
      is_email_notifications_plugin_available = Kenui::EmailNotificationService.email_notification_plugin_available?(cached_options_for_klient).first
      fetch_email_notification_configuration = if is_email_notifications_plugin_available
                                                 promise do
                                                   Kenui::EmailNotificationService.get_configuration_per_account(params.require(:account_id), cached_options_for_klient)
                                                 end.then do |configuration|
                                                   if configuration.first.is_a?(FalseClass)
                                                     Rails.logger.warn(configuration[1])
                                                     configuration = []
                                                   end
                                                   configuration
                                                 end
                                               else
                                                 nil
                                               end

      fetch_payment_methods_with_details = fetch_payment_methods.then do |pms|
        ops = []
        pms.each do |pm|
          ops << promise do
            Kaui::PaymentMethod.find_by_id(pm.payment_method_id, true, cached_options_for_klient)
          rescue StandardError => e
            # Maybe the plugin is not registered or the plugin threw an exception
            Rails.logger.warn(e)
            nil
          end
        end
        ops
      end
      fetch_available_tags = promise { Kaui::TagDefinition.all_for_account(cached_options_for_klient) }

      @overdue_state = wait(fetch_overdue_state)
      @tags = wait(fetch_account_tags)
      @custom_fields = wait(fetch_account_fields)
      @account_emails = wait(fetch_account_emails)
      wait(fetch_payment_methods)
      @payment_methods = wait(fetch_payment_methods_with_details).map { |pm_f| wait(pm_f) }.compact
      @available_tags = wait(fetch_available_tags)
      @children = wait(fetch_children)
      @account_parent = @account.parent_account_id.nil? ? nil : wait(fetch_parent)
      @email_notification_configuration = wait(fetch_email_notification_configuration) if is_email_notifications_plugin_available

      @last_transaction_by_payment_method_id = {}
      wait(fetch_payments).each do |payment|
        transaction = payment.transactions.last
        transaction_date = Date.parse(transaction.effective_date)

        last_seen_transaction_date = @last_transaction_by_payment_method_id[payment.payment_method_id]
        @last_transaction_by_payment_method_id[payment.payment_method_id] = transaction if last_seen_transaction_date.nil? || Date.parse(last_seen_transaction_date.effective_date) < transaction_date
      end

      params.permit!
    end
    # rubocop:enable Style/MultilineBlockChain

    def destroy
      account_id = params.require(:account_id)
      options = params[:options] || []

      cancel_subscriptions = options.include?('cancel_all_subscriptions')
      writeoff_unpaid_invoices = options.include?('writeoff_unpaid_invoices')
      item_adjust_unpaid_invoices = options.include?('item_adjust_unpaid_invoices')
      cached_options_for_klient = options_for_klient

      begin
        @account = Kaui::Account.find_by_id_or_key(account_id, false, false, cached_options_for_klient)
        @account.close(cancel_subscriptions, writeoff_unpaid_invoices, item_adjust_unpaid_invoices, current_user.kb_username, nil, nil, cached_options_for_klient)

        flash[:notice] = "Account #{account_id} successfully closed"
      rescue StandardError => e
        flash[:error] = "Error while closing account: #{as_string(e)}"
      end

      redirect_to account_path(account_id)
    end

    def trigger_invoice
      account_id = params.require(:account_id)
      target_date = params[:target_date].presence
      dry_run = params[:dry_run].nil? ? false : params[:dry_run] == '1'

      invoice = nil
      begin
        invoice = if dry_run
                    Kaui::Invoice.trigger_invoice_dry_run(account_id, target_date, false, options_for_klient)
                  else
                    Kaui::Invoice.trigger_invoice(account_id, target_date, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
                  end
      rescue KillBillClient::API::NotFound
        # Null invoice
      end

      if invoice.nil?
        redirect_to account_path(account_id), notice: "Nothing to generate for target date #{target_date.nil? ? 'today' : target_date}"
      elsif dry_run
        @invoice = Kaui::Invoice.build_from_raw_invoice(invoice)
        @invoice_tags = []
        @available_invoice_tags = []
        @payments = []
        @payment_methods = nil
        @account = Kaui::Account.find_by_id(account_id, false, false, options_for_klient)
        render template: 'kaui/invoices/show'
      else
        # Redirect to fetch payments, etc.
        redirect_to invoice_path(invoice.invoice_id, account_id:), notice: "Generated invoice #{invoice.invoice_number} for target date #{invoice.target_date}"
      end
    end

    # Fetched asynchronously, as it takes time. This also helps with enforcing permissions.
    def next_invoice_date
      json_response do
        next_invoice = Kaui::Invoice.trigger_invoice_dry_run(params.require(:account_id), nil, true, options_for_klient)
        next_invoice ? next_invoice.target_date.to_json : nil
      end
    end

    def edit; end

    def update
      @account = Kaui::Account.new(params.require(:account).delete_if { |_key, value| value.blank? })
      @account.account_id = params.require(:account_id)

      # Transform "1" into boolean
      @account.is_migrated = @account.is_migrated == '1'

      @account.update(true, current_user.kb_username, params[:reason], params[:comment], options_for_klient)

      redirect_to account_path(@account.account_id), notice: 'Account successfully updated'
    rescue StandardError => e
      flash.now[:error] = "Error while updating account: #{as_string(e)}"
      render action: :edit
    end

    def set_default_payment_method
      account_id = params.require(:account_id)
      payment_method_id = params.require(:payment_method_id)

      Kaui::PaymentMethod.set_default(payment_method_id, account_id, current_user.kb_username, params[:reason], params[:comment], options_for_klient)

      redirect_to account_path(account_id), notice: "Successfully set #{payment_method_id} as default"
    end

    def pay_all_invoices
      payment = Kaui::InvoicePayment.new(account_id: params.require(:account_id))

      payment.bulk_create(params[:is_external_payment] == 'true', nil, nil, current_user.kb_username, params[:reason], params[:comment], options_for_klient)

      redirect_to account_path(payment.account_id), notice: 'Successfully triggered a payment for all unpaid invoices'
    end

    def validate_external_key
      json_response do
        external_key = params.require(:external_key)

        begin
          account = Kaui::Account.find_by_external_key(external_key, false, false, options_for_klient)
        rescue KillBillClient::API::NotFound
          account = nil
        end
        { is_found: !account.nil? }
      end
    end

    def link_to_parent
      @account = Kaui::Account.new(params.require(:account).delete_if { |_key, value| value.blank? })
      @account.account_id = params.require(:account_id)
      @account.is_payment_delegated_to_parent = @account.is_payment_delegated_to_parent == '1'

      raise('Account id and account parent id cannot be equal.') if @account.account_id == @account.parent_account_id

      cached_options_for_klient = options_for_klient

      # check if parent id is valid
      Kaui::Account.find_by_id(@account.parent_account_id, false, false, cached_options_for_klient)

      @account.update(false, current_user.kb_username, params[:reason], params[:comment], cached_options_for_klient)

      redirect_to account_path(@account.account_id), notice: 'Account successfully updated'
    rescue StandardError => e
      flash[:error] = if e.is_a?(KillBillClient::API::NotFound)
                        "Parent account id not found: #{@account.parent_account_id}"
                      else
                        "Error while linking parent account: #{as_string(e)}"
                      end
      redirect_to account_path(@account.account_id)
    end

    def unlink_to_parent
      account_id = params.require(:account_id)
      cached_options_for_klient = options_for_klient

      # search for the account and remove the parent account id
      # check if parent id is valid
      account = Kaui::Account.find_by_id(account_id, false, false, cached_options_for_klient)
      account.is_payment_delegated_to_parent = false
      account.parent_account_id = nil
      account.update(true, current_user.kb_username, params[:reason], params[:comment], cached_options_for_klient)

      redirect_to account_path(@account.account_id), notice: 'Account successfully updated'
    rescue StandardError => e
      flash[:error] = "Error while un-linking parent account: #{as_string(e)}"
      redirect_to account_path(@account.account_id)
    end

    def set_email_notifications_configuration
      configuration = params.require(:configuration)
      account_id = configuration[:account_id]
      event_types = configuration[:event_types]
      cached_options_for_klient = options_for_klient

      is_success, message = email_notification_plugin_available?(cached_options_for_klient)

      if is_success
        is_success, message = Kenui::EmailNotificationService.set_configuration_per_account(account_id,
                                                                                            event_types,
                                                                                            current_user.kb_username,
                                                                                            params[:reason],
                                                                                            params[:comment],
                                                                                            cached_options_for_klient)
      end
      if is_success
        flash[:notice] = message
      else
        flash[:error] = message
      end
      redirect_to account_path(account_id)
    end

    def events_to_consider
      json_response do
        { data: Kenui::EmailNotificationService.get_events_to_consider(options_for_klient) }
      end
    end

    private

    def email_notification_plugin_available?(options_for_klient)
      error_message = 'Email notification plugin is not installed'

      is_available = Kenui::EmailNotificationService.email_notification_plugin_available?(options_for_klient).first
      [is_available, is_available ? nil : error_message]
    rescue StandardError
      [false, error_message]
    end
  end
end
