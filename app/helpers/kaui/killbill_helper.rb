require 'rest_client'

module Kaui
  module KillbillHelper

    def self.call_killbill(method, uri, *args)
      url = Kaui.killbill_finder.call + uri
      Rails.logger.info "Performing #{method} request to #{url}"
      begin
        response = RestClient.send(method.to_sym, url, *args)
        data = { :code => response.code }
        if response.code < 300 && response.body.present?
          if response.headers[:content_type] =~ /application\/json.*/
            data[:json] = JSON.parse(response.body)
          else
            data[:body] = response.body
          end
        end
        data
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
        raise e
      end
    end

    def self.process_response(response, arity, &block)
      if response.nil? || response[:json].nil?
        arity == :single ? nil : []
      elsif block_given?
        arity == :single ? yield(response[:json]) : response[:json].collect {|item| yield(item) }
      else
        response[:json]
      end
    end

    def self.extract_reason_code(reason)
      reason_code = $1 if reason =~ /\s*(\d+).*/
    end

    ############## ACCOUNT ##############

    def self.get_account_by_key(key, with_balance)
      # support id (UUID) and external key search
      if key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
        Kaui::KillbillHelper.get_account(key, with_balance)
      else
        Kaui::KillbillHelper.get_account_by_external_key(key, with_balance)
      end
    end

    def self.get_account_timeline(account_id)
      data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/timeline?audit=MINIMAL"
      process_response(data, :single) {|json| Kaui::AccountTimeline.new(json) }
    end

    def self.get_account(account_id, with_balance=false)
      data = call_killbill :get, "/1.0/kb/accounts/#{account_id}?accountWithBalance=#{with_balance}"
      process_response(data, :single) {|json| Kaui::Account.new(json) }
    end

    def self.get_account_by_external_key(external_key, with_balance=false)
      data = call_killbill :get, "/1.0/kb/accounts?externalKey=#{external_key}&accountWithBalance=#{with_balance}"
      process_response(data, :single) {|json| Kaui::Account.new(json) }
    end

    def self.get_account_by_bundle_id(bundle_id)
      bundle = get_bundle(bundle_id)
      account = get_account(bundle.account_id)
    end

    def self.get_account_emails(account_id)
      data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/emails"
      process_response(data, :multiple) { |json| Kaui::AccountEmail.new(json) }
    end

    def self.add_account_email(account_email, current_user = nil, reason = nil, comment = nil)
      account_email_data = Kaui::AccountEmail.camelize(account_email.to_hash)
      call_killbill :post,
                    "/1.0/kb/accounts/#{account_email.account_id}/emails",
                    ActiveSupport::JSON.encode(account_email_data, :root => false),
                    :content_type => "application/json",
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => extract_reason_code(reason),
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.remove_account_email(account_email, current_user = nil, reason = nil, comment = nil)
      call_killbill :delete,
                    "/1.0/kb/accounts/#{account_email.account_id}/emails/#{account_email.email}",
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => "#{reason}",
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.update_email_notifications(account_id, is_notified, current_user = nil, reason = nil, comment = nil)
      email_data = { :isNotifiedForInvoices => is_notified }
      call_killbill :put,
                    "/1.0/kb/accounts/#{account_id}/emailNotifications",
                    ActiveSupport::JSON.encode(email_data, :root => false),
                    :content_type => "application/json",
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => extract_reason_code(reason),
                    "X-Killbill-Comment" => "#{comment}"
    end

    ############## BUNDLE ##############

    def self.get_bundle_by_key(key, account_id)
      # support id (UUID) and external key search
      if key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
        @bundle = Kaui::KillbillHelper::get_bundle(key)
      else
        @bundle = Kaui::KillbillHelper::get_bundle_by_external_key(key, account_id)
      end
    end

    def self.get_bundles(account_id)
      data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/bundles"
      process_response(data, :multiple) {|json| Kaui::Bundle.new(json) }
    end

    def self.get_bundle_by_external_key(account_id, external_key)
      data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/bundles?externalKey=#{external_key}"
      process_response(data, :single) {|json| Kaui::Bundle.new(json) }
    end

    def self.get_bundle(bundle_id)
      data = call_killbill :get, "/1.0/kb/bundles/#{bundle_id}"
      process_response(data, :single) {|json| Kaui::Bundle.new(json) }
    end

    def self.transfer_bundle(bundle_id, new_account_id, cancel_immediately = false, transfer_addons = true, current_user = nil, reason = nil, comment = nil)
      call_killbill :put,
                    "/1.0/kb/bundles/#{bundle_id}?cancelImmediately=#{cancel_immediately}&transferAddOn=#{transfer_addons}",
                    ActiveSupport::JSON.encode("accountId" => new_account_id),
                    :content_type => :json,
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => "#{reason}",
                    "X-Killbill-Comment" => "#{comment}"
    end

    ############## SUBSCRIPTION ##############

    def self.get_subscriptions_for_bundle(bundle_id)
      data = call_killbill :get, "/1.0/kb/bundles/#{bundle_id}/subscriptions"
      process_response(data, :multiple) {|json| Kaui::Subscription.new(json) }
    end

    def self.get_subscriptions(account_id)
      subscriptions = []
      bundles = get_bundles(account_id)
      bundles.each do |bundle|
        subscriptions += get_subscriptions_for_bundle(bundle.bundle_id)
      end
      subscriptions
    end

    def self.get_subscription(subscription_id)
      data = call_killbill :get, "/1.0/kb/subscriptions/#{subscription_id}"
      process_response(data, :single) {|json| Kaui::Subscription.new(json) }
    end

    def self.create_subscription(subscription, current_user = nil, reason = nil, comment = nil)
      subscription_data = Kaui::Subscription.camelize(subscription.to_hash)
      # We don't want to pass events
      subscription_data.delete(:events)
      call_killbill :post,
                    "/1.0/kb/subscriptions",
                    ActiveSupport::JSON.encode(subscription_data, :root => false),
                    :content_type => "application/json",
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => "#{reason}",
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.update_subscription(subscription, requested_date = nil, current_user = nil, reason = nil, comment = nil)
      subscription_data = Kaui::Subscription.camelize(subscription.to_hash)
      date_param = "?requestedDate=" + requested_date.to_s unless requested_date.blank?
      # We don't want to pass events
      subscription_data.delete(:events)
      call_killbill :put,
                    "/1.0/kb/subscriptions/#{subscription.subscription_id}#{date_param}",
                    ActiveSupport::JSON.encode(subscription_data, :root => false),
                    :content_type => :json,
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => "#{reason}",
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.reinstate_subscription(subscription_id, current_user = nil, reason = nil, comment = nil)
      call_killbill :put,
                    "/1.0/kb/subscriptions/#{subscription_id}/uncancel",
                    "",
                    :content_type => :json,
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => "#{reason}",
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.delete_subscription(subscription_id, current_user = nil, reason = nil, comment = nil)
      call_killbill :delete,
                    "/1.0/kb/subscriptions/#{subscription_id}",
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => "#{reason}",
                    "X-Killbill-Comment" => "#{comment}"
    end

    ############## INVOICE ##############

    def self.get_invoice(invoice_id)
      data = call_killbill :get, "/1.0/kb/invoices/#{invoice_id}?withItems=true"
      process_response(data, :single) {|json| Kaui::Invoice.new(json) }
    end

    def self.get_invoice_item(invoice_id, invoice_item_id)
      # Find the item from the invoice
      # TODO add killbill-server API
      invoice = Kaui::KillbillHelper.get_invoice(invoice_id)
      if invoice.present? and invoice.items.present?
        invoice.items.each do |item|
          return item if item.invoice_item_id == invoice_item_id
        end
      end
      nil
    end

    def self.get_invoice_html(invoice_id)
      data = call_killbill :get, "/1.0/kb/invoices/#{invoice_id}/html"
      data[:body] if data.present?
    end

    def self.adjust_invoice(invoice_item, current_user = nil, reason = nil, comment = nil)
      invoice_data = Kaui::InvoiceItem.camelize(invoice_item.to_hash)
      call_killbill :post,
                    "/1.0/kb/invoices/#{invoice_item.invoice_id}",
                    ActiveSupport::JSON.encode(invoice_data, :root => false),
                    :content_type => :json,
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => "#{reason}",
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.create_charge(charge, requested_date, current_user = nil, reason = nil, comment = nil)
      charge_data = Kaui::Charge.camelize(charge.to_hash)
      date_param = "?requestedDate=" + requested_date unless requested_date.blank?

      if charge.invoice_id.present?
        call_killbill :post,
                      "/1.0/kb/invoices/#{charge.invoice_id}/charges#{date_param}",
                      ActiveSupport::JSON.encode(charge_data, :root => false),
                      :content_type => "application/json",
                      "X-Killbill-CreatedBy" => current_user,
                      "X-Killbill-Reason" => extract_reason_code(reason),
                      "X-Killbill-Comment" => "#{comment}"
      else
        call_killbill :post,
                      "/1.0/kb/invoices/charges#{date_param}",
                      ActiveSupport::JSON.encode(charge_data, :root => false),
                      :content_type => "application/json",
                      "X-Killbill-CreatedBy" => current_user,
                      "X-Killbill-Reason" => extract_reason_code(reason),
                      "X-Killbill-Comment" => "#{comment}"
      end
    end

    ############## CATALOG ##############

    def self.get_full_catalog
      data = call_killbill :get, "/1.0/kb/catalog/simpleCatalog"
      data[:json]
    end

    def self.get_available_addons(base_product_name)
      data = call_killbill :get, "/1.0/kb/catalog/availableAddons?baseProductName=#{base_product_name}"
      if data.has_key?(:json)
        data[:json].inject({}) {|catalog_hash, item| catalog_hash.merge!(item["planName"] => item) }
      end
    end

    def self.get_available_base_plans()
      data = call_killbill :get, "/1.0/kb/catalog/availableBasePlans"
      if data.has_key?(:json)
        data[:json].inject({}) {|catalog_hash, item| catalog_hash.merge!(item["planName"] => item) }
      end
    end

    ############## PAYMENT ##############

    def self.get_payment(payment_id)
      data = call_killbill :get, "/1.0/kb/payments/#{payment_id}"
      process_response(data, :single) { |json| Kaui::Payment.new(json) }
    end

    def self.get_payments(invoice_id)
      data = call_killbill :get, "/1.0/kb/invoices/#{invoice_id}/payments"
      response_data = process_response(data, :multiple) {|json| Kaui::Payment.new(json) }
      return response_data
    end

    def self.create_payment(payment, external, current_user = nil, reason = nil, comment = nil)
      payment_data = Kaui::Payment.camelize(payment.to_hash)

      if payment.invoice_id.present?
        # We should use different model for POST and GEt, this seems fragile...
        payment_data.delete(:external)
        payment_data.delete(:refunds)
        payment_data.delete(:chargebacks)
        payment_data.delete(:audit_logs)
        call_killbill :post,
                       "/1.0/kb/invoices/#{payment.invoice_id}/payments?externalPayment=#{external}",
                       ActiveSupport::JSON.encode(payment_data, :root => false),
                       :content_type => "application/json",
                       "X-Killbill-CreatedBy" => current_user,
                       "X-Killbill-Reason" => extract_reason_code(reason),
                       "X-Killbill-Comment" => "#{comment}"
      end
    end

    ############## PAYMENT METHOD ##############

    def self.delete_payment_method(payment_method_id, set_auto_pay_off = false,  current_user = nil, reason = nil, comment = nil)
      set_auto_pay_off_param = "?deleteDefaultPmWithAutoPayOff=true" if set_auto_pay_off
      call_killbill :delete,
                    "/1.0/kb/paymentMethods/#{payment_method_id}#{set_auto_pay_off_param}",
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => "#{reason}",
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.get_payment_methods(account_id)
      data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/paymentMethods?withPluginInfo=true"
      process_response(data, :multiple) {|json| Kaui::PaymentMethod.new(json) }
    end

    def self.get_payment_method(payment_method_id)
      data = call_killbill :get, "/1.0/kb/paymentMethods/#{payment_method_id}?withPluginInfo=true"
      process_response(data, :single) {|json| Kaui::PaymentMethod.new(json) }
    end

    def self.set_payment_method_as_default(account_id, payment_method_id, current_user = nil, reason = nil, comment = nil)
      call_killbill :put,
                    "/1.0/kb/accounts/#{account_id}/paymentMethods/#{payment_method_id}/setDefault",
                    "",
                    :content_type => :json,
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => extract_reason_code(reason),
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.add_payment_method(payment_method, current_user = nil, reason = nil, comment = nil)
      payment_method_data = Kaui::Refund.camelize(payment_method.to_hash)
        call_killbill :post,
                      "/1.0/kb/accounts/#{payment_method.account_id}/paymentMethods?isDefault=#{payment_method.is_default}",
                      ActiveSupport::JSON.encode(payment_method_data, :root => false),
                      :content_type => :json,
                      "X-Killbill-CreatedBy" => current_user,
                      "X-Killbill-Reason" => extract_reason_code(reason),
                      "X-Killbill-Comment" => "#{comment}"
    end

    ############## REFUND ##############

    def self.get_refund(refund_id)
      data = call_killbill :get, "/1.0/kb/refunds/#{refund_id}"
      process_response(data, :single) { |json| Kaui::Refund.new(json) }
    end

    def self.get_refunds_for_payment(payment_id)
      data = call_killbill :get, "/1.0/kb/payments/#{payment_id}/refunds"
      process_response(data, :multiple) {|json| Kaui::Refund.new(json) }
    end

    def self.create_refund(payment_id, refund, current_user = nil, reason = nil, comment = nil)
      refund_data = Kaui::Refund.camelize(refund.to_hash)

      call_killbill :post,
                    "/1.0/kb/payments/#{payment_id}/refunds",
                    ActiveSupport::JSON.encode(refund_data, :root => false),
                    :content_type => "application/json",
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => extract_reason_code(reason),
                    "X-Killbill-Comment" => "#{comment}"
    end

    ############## CHARGEBACK ##############

    def self.get_chargebacks_for_payment(payment_id)
      data = call_killbill :get, "/1.0/kb/chargebacks/payments/#{payment_id}"
      process_response(data, :multiple) {|json| Kaui::Chargeback.new(json) }
    end

    def self.create_chargeback(chargeback, current_user = nil, reason = nil, comment = nil)
      chargeback_data = Kaui::Refund.camelize(chargeback.to_hash)

      call_killbill :post,
                    "/1.0/kb/chargebacks",
                    ActiveSupport::JSON.encode(chargeback_data, :root => false),
                    :content_type => "application/json",
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => extract_reason_code(reason),
                    "X-Killbill-Comment" => "#{comment}"
    end

    ############## CREDIT ##############

    def self.create_credit(credit, current_user = nil, reason = nil, comment = nil)
      credit_data = Kaui::Credit.camelize(credit.to_hash)
      call_killbill :post,
                    "/1.0/kb/credits",
                    ActiveSupport::JSON.encode(credit_data, :root => false),
                    :content_type => "application/json",
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => extract_reason_code(reason),
                    "X-Killbill-Comment" => "#{comment}"
    end

    ############## TAG ##############

    def self.get_tag_definitions
      data = call_killbill :get, "/1.0/kb/tagDefinitions"
      process_response(data, :multiple) { |json| Kaui::TagDefinition.new(json) }
    end

    def self.get_tag_definition(tag_definition_id)
      data = call_killbill :get, "/1.0/kb/tagDefinitions/#{tag_definition_id}"
      process_response(data, :single) { |json| Kaui::TagDefinition.new(json) }
    end

    def self.create_tag_definition(tag_definition, current_user = nil, reason = nil, comment = nil)
      tag_definition_data = Kaui::TagDefinition.camelize(tag_definition.to_hash)
      call_killbill :post,
                    "/1.0/kb/tagDefinitions",
                    ActiveSupport::JSON.encode(tag_definition_data, :root => false),
                    :content_type => "application/json",
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => extract_reason_code(reason),
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.delete_tag_definition(tag_definition_id, current_user = nil, reason = nil, comment = nil)
      call_killbill :delete,
                    "/1.0/kb/tagDefinitions/#{tag_definition_id}",
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => "#{reason}",
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.get_tags_for_account(account_id)
      data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/tags"
      process_response(data, :multiple) { |json| Kaui::Tag.new(json) }
    end

    def self.get_tags_for_bundle(bundle_id)
      data = call_killbill :get, "/1.0/kb/bundles/#{bundle_id}/tags"
      return data[:json]
    end


    def self.add_tags_for_account(account_id, tags, current_user = nil, reason = nil, comment = nil)
      call_killbill :post,
                    "/1.0/kb/accounts/#{account_id}/tags?" + RestClient::Payload.generate(:tagList => tags.join(",")).to_s,
                    nil,
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => "#{reason}",
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.remove_tags_for_account(account_id, tags, current_user = nil, reason = nil, comment = nil)
      return if !tags.present? || tags.size == 0
      call_killbill :delete,
                    "/1.0/kb/accounts/#{account_id}/tags?" + RestClient::Payload.generate(:tagList => tags.join(",")).to_s,
                    "X-Killbill-CreatedBy" => current_user,
                    "X-Killbill-Reason" => "#{reason}",
                    "X-Killbill-Comment" => "#{comment}"
    end

    def self.set_tags_for_bundle(bundle_id, tags, current_user = nil, reason = nil, comment = nil)
      if tags.nil? || tags.empty?
      else
        call_killbill :post,
                      "/1.0/kb/bundles/#{bundle_id}/tags?" + RestClient::Payload.generate(:tag_list => tags.join(",")).to_s,
                      nil,
                      "X-Killbill-CreatedBy" => current_user,
                      "X-Killbill-Reason" => "#{reason}",
                      "X-Killbill-Comment" => "#{comment}"
      end
    end

    ############## ANALYTICS ##############

    def self.get_accounts_created_over_time
      data = call_killbill :get, "/1.0/kb/analytics/accountsCreatedOverTime"
      process_response(data, :single) { |json| Kaui::TimeSeriesData.new(json) }
    end

    def self.get_subscriptions_created_over_time(product_type, slug)
      data = call_killbill :get, "/1.0/kb/analytics/subscriptionsCreatedOverTime?productType=#{product_type}&slug=#{slug}"
      process_response(data, :single) { |json| Kaui::TimeSeriesData.new(json) }
    end
  end
end
