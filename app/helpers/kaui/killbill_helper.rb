require 'killbill_client'
require 'base64'

module Kaui
  module KillbillHelper

    def self.call_killbill(method, uri, *args)
      url = Kaui.killbill_finder.call + uri
      Rails.logger.info "Performing #{method} request to #{url}"
      begin
        # Temporary hacks until we get rid of this class
        args[0] = {} if args.empty?
        # Multi-tenancy hack
        args[-1] ||= {}
        args[-1]["X-Killbill-ApiKey"] = args[-1][:api_key]
        args[-1]["X-Killbill-ApiSecret"] = args[-1][:api_secret]
        # RBAC hack
        if args[-1][:username] and args[-1][:password]
          args[-1]["Authorization"] = 'Basic ' + Base64.encode64("#{args[-1][:username]}:#{args[-1][:password]}").chomp
        end
        if args[-1][:session_id]
          args[-1]["Cookie"] = "JSESSIONID=#{args[-1][:session_id]}"
        end
        [:api_key, :api_secret, :username, :password, :session_id].each { |k| args[-1].delete(k) }

        response = RestClient.send(method.to_sym, url, *args)
        data = {:code => response.code}
        if response.code < 300 && response.body.present?
          # Hack for Analytics plugin (no content-type header returned)
          begin
            data[:json] = JSON.parse(response.body)
          rescue => e
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
        arity == :single ? yield(response[:json]) : response[:json].collect { |item| yield(item) }
      else
        response[:json]
      end
    end

    def self.extract_reason_code(reason)
      reason_code = reason
      reason_code = $1 if reason =~ /\s*(\d+).*/
      reason_code
    end

    def self.build_audit_headers(current_user, reason, comment, options)
      {
        :content_type => "application/json",
        "X-Killbill-CreatedBy" => extract_created_by(current_user),
        "X-Killbill-Reason" => extract_reason_code(reason),
        "X-Killbill-Comment" => "#{comment}",
      }.merge(options)
    end

    def self.extract_created_by(current_user)
      current_user.respond_to?(:kb_username) ? current_user.kb_username : current_user.to_s
    end

    ############## ACCOUNT ##############

    def self.get_accounts(offset, limit, options = {})
      KillBillClient::Model::Account.find_in_batches offset, limit, false, false, options
    end

    def self.search_accounts(search_key, offset, limit, options = {})
      KillBillClient::Model::Account.find_in_batches_by_search_key search_key, offset, limit, false, false, options
    end

    def self.get_account_by_key_with_balance_and_cba(key, options = {})
      self.get_account_by_key(key, false, true, options)
    end

    def self.get_account_by_key(key, with_balance = false, with_balance_and_cba = false, options = {})
      # support id (UUID) and external key search
      if key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
        Kaui::KillbillHelper.get_account(key, with_balance, with_balance_and_cba, options)
      else
        Kaui::KillbillHelper.get_account_by_external_key(key, with_balance, with_balance_and_cba, options)
      end
    end

    def self.get_account_timeline(account_id, audit = "MINIMAL", options = {})
      KillBillClient::Model::AccountTimeline.find_by_account_id account_id, audit, options
    end

    def self.get_account(account_id, with_balance = false, with_balance_and_cba = false, options = {})
      data = call_killbill :get, "/1.0/kb/accounts/#{account_id}?accountWithBalance=#{with_balance}&accountWithBalanceAndCBA=#{with_balance_and_cba}", options
      process_response(data, :single) { |json| Kaui::Account.new(json) }
    end

    def self.get_account_by_external_key(external_key, with_balance = false, with_balance_and_cba = false, options = {})
      data = call_killbill :get, "/1.0/kb/accounts?externalKey=#{external_key}&accountWithBalance=#{with_balance}&accountWithBalanceAndCBA=#{with_balance_and_cba}", options
      process_response(data, :single) { |json| Kaui::Account.new(json) }
    end

    def self.get_account_by_bundle_id(bundle_id, options = {})
      bundle = get_bundle(bundle_id, options)
      get_account(bundle.account_id, false, false, options)
    end

    def self.get_account_emails(account_id, options = {})
      data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/emails", options
      process_response(data, :multiple) { |json| Kaui::AccountEmail.new(json) }
    end

    def self.add_account_email(account_email, current_user = nil, reason = nil, comment = nil, options = {})
      account_email_data = Kaui::AccountEmail.camelize(account_email.to_hash)
      call_killbill :post,
                    "/1.0/kb/accounts/#{account_email.account_id}/emails",
                    ActiveSupport::JSON.encode(account_email_data, :root => false),
                    build_audit_headers(current_user, reason, comment, options)
    end

    def self.remove_account_email(account_email, current_user = nil, reason = nil, comment = nil, options = {})
      call_killbill :delete,
                    "/1.0/kb/accounts/#{account_email.account_id}/emails/#{account_email.email}",
                    build_audit_headers(current_user, reason, comment, options)
    end

    def self.update_email_notifications(account_id, is_notified, current_user = nil, reason = nil, comment = nil, options = {})
      email_data = {:isNotifiedForInvoices => is_notified}
      call_killbill :put,
                    "/1.0/kb/accounts/#{account_id}/emailNotifications",
                    ActiveSupport::JSON.encode(email_data, :root => false),
                    build_audit_headers(current_user, reason, comment, options)
    end

    ############## BUNDLE ##############

    def self.get_bundle_by_key(key, account_id = nil, options = {})
      # support id (UUID) and external key search
      if key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
        Kaui::KillbillHelper::get_bundle(key, options)
      else
        raise ArgumentError.new("account id not specified") if account_id.blank?
        bundles = KillBillClient::Model::Bundle.find_all_by_account_id_and_external_key account_id, key, options
        bundles.empty? ? nil : bundles[-1]
      end
    end

    def self.get_bundles(account_id, options = {})
      account = KillBillClient::Model::Account.find_by_id account_id, false, false, options
      account.bundles options
    end

    def self.get_bundle(bundle_id, options = {})
      KillBillClient::Model::Bundle::find_by_id(bundle_id, options)
    end

    def self.transfer_bundle(bundle_id, new_account_id, cancel_immediately = false, transfer_addons = true, current_user = nil, reason = nil, comment = nil, options = {})
      call_killbill :put,
                    "/1.0/kb/bundles/#{bundle_id}?cancelImmediately=#{cancel_immediately}&transferAddOn=#{transfer_addons}",
                    ActiveSupport::JSON.encode("accountId" => new_account_id),
                    build_audit_headers(current_user, reason, comment, options)
    end

    ############## SUBSCRIPTION ##############

    def self.get_subscription(subscription_id, options = {})
      KillBillClient::Model::Subscription::find_by_id(subscription_id, options)
    end

    def self.create_subscription(subscription, current_user = nil, reason = nil, comment = nil, options = {})
      entitlement = KillBillClient::Model::Subscription.new
      entitlement.account_id = subscription.account_id
      entitlement.bundle_id = subscription.bundle_id
      entitlement.external_key = subscription.external_key
      entitlement.product_name = subscription.product_name
      entitlement.product_category = subscription.product_category
      entitlement.billing_period = subscription.billing_period
      entitlement.price_list = subscription.price_list

      entitlement.create(extract_created_by(current_user), extract_reason_code(reason), comment, options)
    end

    def self.update_subscription(subscription, requested_date = nil, policy = nil, current_user = nil, reason = nil, comment = nil, options = {})
      requested_date = requested_date.to_s unless requested_date.blank?
      entitlement = KillBillClient::Model::Subscription.new
      entitlement.subscription_id = subscription.subscription_id
      entitlement.change_plan({:productName => subscription.product_name, :billingPeriod => subscription.billing_period, :priceList => subscription.price_list},
                              extract_created_by(current_user), extract_reason_code(reason), comment, requested_date, policy, false, options)
    end

    def self.delete_subscription(subscription_id, current_user = nil, reason = nil, comment = nil,  entitlement_policy = nil, billing_policy = nil, options = {})
      entitlement = KillBillClient::Model::Subscription.new
      entitlement.subscription_id = subscription_id
      entitlement.cancel(extract_created_by(current_user), extract_reason_code(reason), comment, nil, entitlement_policy, billing_policy, true, options)
    end

    def self.reinstate_subscription(subscription_id, current_user = nil, reason = nil, comment = nil, options = {})
      call_killbill :put,
                    "/1.0/kb/subscriptions/#{subscription_id}/uncancel",
                    "",
                    build_audit_headers(current_user, reason, comment, options)
    end

    def self.compute_previous_ctd(ctd, billing_period, options = {})
      return nil if ctd.nil? or billing_period.nil?

      ctd = DateTime.parse(ctd)
      billing_period = billing_period.upcase
      if billing_period == 'MONTHLY'
        ctd.prev_month(1)
      elsif billing_period == 'QUARTERLY'
        ctd.prev_month(3)
      elsif billing_period == 'ANNUAL'
        ctd.prev_month(12)
      else
        nil
      end
    end

    ############## INVOICE ##############

    def self.get_invoices(offset, limit, options = {})
      KillBillClient::Model::Invoice.find_in_batches offset, limit, options
    end

    def self.get_invoice(id_or_number, with_items = true, audit = "NONE", options = {})
      KillBillClient::Model::Invoice.find_by_id_or_number id_or_number, with_items, audit, options
    end

    def self.get_invoice_item(invoice_id, invoice_item_id, options = {})
      # Find the item from the invoice
      # TODO add killbill-server API
      invoice = Kaui::KillbillHelper.get_invoice(invoice_id, true, "NONE", options)
      if invoice.present? and invoice.items.present?
        invoice.items.each do |item|
          return item if item.invoice_item_id == invoice_item_id
        end
      end
      nil
    end

    def self.new_invoice_item(invoice_item)
      item = KillBillClient::Model::InvoiceItem.new
      invoice_item.each do |attribute, value|
        item.methods.include?("#{attribute}=".to_sym) ?
        item.send("#{attribute}=".to_sym, value) : next
      end
      item
    end

    def self.get_invoice_html(invoice_id, options = {})
      data = call_killbill :get, "/1.0/kb/invoices/#{invoice_id}/html", options
      data[:body] if data.present?
    end

    def self.adjust_invoice(invoice_item, current_user = nil, reason = nil, comment = nil, options = {})
      invoice_data = Kaui::InvoiceItem.camelize(invoice_item.to_hash)
      call_killbill :post,
                    "/1.0/kb/invoices/#{invoice_item.invoice_id}",
                    ActiveSupport::JSON.encode(invoice_data, :root => false),
                    build_audit_headers(current_user, reason, comment, options)
    end

    def self.create_charge(charge, requested_date, current_user = nil, reason = nil, comment = nil, options = {})
      charge_data = Kaui::Charge.camelize(charge.to_hash)
      date_param = "?requestedDate=" + requested_date unless requested_date.blank?

      if charge.invoice_id.present?
        call_killbill :post,
                      "/1.0/kb/invoices/#{charge.invoice_id}/charges#{date_param}",
                      ActiveSupport::JSON.encode(charge_data, :root => false),
                      build_audit_headers(current_user, reason, comment, options)
      else
        call_killbill :post,
                      "/1.0/kb/invoices/charges#{date_param}",
                      ActiveSupport::JSON.encode(charge_data, :root => false),
                      build_audit_headers(current_user, reason, comment, options)
      end
    end

    def self.delete_cba(account_id, invoice_id, invoice_item_id, current_user = nil, reason = nil, comment = nil, options = {})
      call_killbill :delete,
                    "/1.0/kb/invoices/#{invoice_id}/#{invoice_item_id}/cba?accountId=#{account_id}",
                    build_audit_headers(current_user, reason, comment, options)
    end

    ############## CATALOG ##############

    def self.get_full_catalog(options = {})
      data = call_killbill :get, "/1.0/kb/catalog/simpleCatalog", options
      data[:json]
    end

    def self.get_available_addons(base_product_name, options = {})
      data = call_killbill :get, "/1.0/kb/catalog/availableAddons?baseProductName=#{base_product_name}", options
      if data.has_key?(:json)
        data[:json].inject({}) { |catalog_hash, item| catalog_hash.merge!(item["planName"] => item) }
      end
    end

    def self.get_available_base_plans(options = {})
      data = call_killbill :get, "/1.0/kb/catalog/availableBasePlans", options
      if data.has_key?(:json)
        data[:json].inject({}) { |catalog_hash, item| catalog_hash.merge!(item["planName"] => item) }
      end
    end

    ############## PAYMENT ##############

    def self.get_payments(offset, limit, options = {})
      KillBillClient::Model::Payment.find_in_batches offset, limit, options
    end

    def self.search_payments(search_key, offset, limit, options = {})
      KillBillClient::Model::Payment.find_in_batches_by_search_key search_key, offset, limit, options
    end

    def self.get_payment(payment_id, options = {})
      data = call_killbill :get, "/1.0/kb/payments/#{payment_id}", options
      process_response(data, :single) { |json| Kaui::Payment.new(json) }
    end

    def self.get_payments_for_invoice(invoice_id, options = {})
      data = call_killbill :get, "/1.0/kb/invoices/#{invoice_id}/payments", options
      response_data = process_response(data, :multiple) { |json| Kaui::Payment.new(json) }
      return response_data
    end

    def self.pay_all_invoices(account_id, external = false, current_user = nil, reason = nil, comment = nil, options = {})
      call_killbill :post,
                    "/1.0/kb/accounts/#{account_id}/payments?externalPayment=#{external}",
                    ActiveSupport::JSON.encode({:accountId => account_id}, :root => false),
                    build_audit_headers(current_user, reason, comment, options)
    end

    def self.create_payment(payment, external, current_user = nil, reason = nil, comment = nil, options = {})
      payment_data = Kaui::Payment.camelize(payment.to_hash)

      if payment.invoice_id.present?
        # We should use different model for POST and GET, this seems fragile...
        payment_data.delete(:external)
        payment_data.delete(:refunds)
        payment_data.delete(:chargebacks)
        payment_data.delete(:audit_logs)
        call_killbill :post,
                      "/1.0/kb/invoices/#{payment.invoice_id}/payments?externalPayment=#{external}",
                      ActiveSupport::JSON.encode(payment_data, :root => false),
                      build_audit_headers(current_user, reason, comment, options)
      end
    end

    ############## PAYMENT METHOD ##############

    def self.get_payment_methods(offset, limit, options = {})
      KillBillClient::Model::PaymentMethod.find_in_batches offset, limit, options
    end

    def self.search_payment_methods(search_key, offset, limit, options = {})
      KillBillClient::Model::PaymentMethod.find_in_batches_by_search_key search_key, offset, limit, options
    end

    def self.delete_payment_method(payment_method_id, set_auto_pay_off = false, current_user = nil, reason = nil, comment = nil, options = {})
      KillBillClient::Model::PaymentMethod.destroy payment_method_id, set_auto_pay_off, extract_created_by(current_user), extract_reason_code(reason), comment, options
    end

    def self.get_non_external_payment_methods(account_id, options = {})
      KillBillClient::Model::PaymentMethod.find_all_by_account_id(account_id, true, options).reject { |x| x.plugin_name == '__EXTERNAL_PAYMENT__' }
    end

    def self.get_payment_method(payment_method_id, options = {})
      KillBillClient::Model::PaymentMethod.find_by_id payment_method_id, true, options
    end

    def self.set_payment_method_as_default(account_id, payment_method_id, current_user = nil, reason = nil, comment = nil, options = {})
      KillBillClient::Model::PaymentMethod.set_default payment_method_id, account_id, extract_created_by(current_user), extract_reason_code(reason), comment, options
    end

    def self.add_payment_method(is_default, payment_method, current_user = nil, reason = nil, comment = nil, options = {})
      payment_method.create is_default, extract_created_by(current_user), extract_reason_code(reason), comment, options
    end

    ############## REFUND ##############

    def self.get_refunds(offset, limit, options = {})
      KillBillClient::Model::Refund.find_in_batches offset, limit, options
    end

    def self.search_refunds(search_key, offset, limit, options = {})
      KillBillClient::Model::Refund.find_in_batches_by_search_key search_key, offset, limit, options
    end

    def self.get_refund(refund_id, options = {})
      KillBillClient::Model::Refund.find_by_id refund_id, options
    end

    def self.get_refunds_for_payment(payment_id, options = {})
      KillBillClient::Model::Refund.find_all_by_payment_id payment_id, options
    end

    def self.create_refund(payment_id, refund, current_user = nil, reason = nil, comment = nil, options = {})

      new_refund = KillBillClient::Model::Refund.new
      new_refund.payment_id = payment_id
      new_refund.amount = refund["amount"]
      new_refund.adjusted = refund["adjusted"]
      if ! refund["adjustments"].nil?
        new_refund.adjustments = []
        refund["adjustments"].each do |a|
          item = KillBillClient::Model::InvoiceItemAttributes.new
          item.invoice_item_id = a.invoice_item_id
          item.amount = a.amount.to_f unless a.amount.nil?
          new_refund.adjustments << item
        end
      end
      #no need to pass adjustment_type
      new_refund.create(extract_created_by(current_user),
                        extract_reason_code(reason),
                        comment,
                        options)
    end

    ############## CHARGEBACK ##############

    def self.get_chargebacks_for_payment(payment_id, options = {})
      data = call_killbill :get, "/1.0/kb/chargebacks/payments/#{payment_id}", options
      process_response(data, :multiple) { |json| Kaui::Chargeback.new(json) }
    end

    def self.create_chargeback(chargeback, current_user = nil, reason = nil, comment = nil, options = {})

      new_chargeback = KillBillClient::Model::Chargeback.new
      new_chargeback.payment_id = chargeback.payment_id
      new_chargeback.amount = chargeback.chargeback_amount
      new_chargeback.create(extract_created_by(current_user),
                            extract_reason_code(reason),
                            comment,
                            options)
    end

    ############## CREDIT ##############

    def self.create_credit(credit, current_user = nil, reason = nil, comment = nil, options = {})
      new_credit = KillBillClient::Model::Credit.new
      new_credit.credit_amount = credit['credit_amount']
      new_credit.invoice_id = credit['invoice_id']
      new_credit.effective_date = credit['effective_date']
      new_credit.account_id = credit['account_id']

      new_credit.create(extract_created_by(current_user),
                        extract_reason_code(reason),
                        comment,
                        options)
    end

    ############## TAG ##############

    def self.get_tags(offset, limit, options = {})
      KillBillClient::Model::Tag.find_in_batches offset, limit, options
    end

    def self.search_tags(search_key, offset, limit, options = {})
      KillBillClient::Model::Tag.find_in_batches_by_search_key search_key, offset, limit, options
    end

    def self.get_tag_definitions(options = {})
      data = call_killbill :get, "/1.0/kb/tagDefinitions", options
      process_response(data, :multiple) { |json| Kaui::TagDefinition.new(json) }
    end

    def self.get_tag_definition(tag_definition_id, options = {})
      data = call_killbill :get, "/1.0/kb/tagDefinitions/#{tag_definition_id}", options
      process_response(data, :single) { |json| Kaui::TagDefinition.new(json) }
    end

    def self.create_tag_definition(tag_definition, current_user = nil, reason = nil, comment = nil, options = {})
      tag_definition_data = Kaui::TagDefinition.camelize(tag_definition.to_hash)
      call_killbill :post,
                    "/1.0/kb/tagDefinitions",
                    ActiveSupport::JSON.encode(tag_definition_data, :root => false),
                    build_audit_headers(current_user, reason, comment, options)
    end

    def self.delete_tag_definition(tag_definition_id, current_user = nil, reason = nil, comment = nil, options = {})
      call_killbill :delete,
                    "/1.0/kb/tagDefinitions/#{tag_definition_id}",
                    build_audit_headers(current_user, reason, comment, options)
    end

    def self.get_tags_for_account(account_id, included_deleted = false, audit = "NONE", options = {})
      KillBillClient::Model::Tag.find_all_by_account_id account_id, included_deleted, audit, options
    end

    def self.get_tags_for_bundle(bundle_id, options = {})
      data = call_killbill :get, "/1.0/kb/bundles/#{bundle_id}/tags", options
      return data[:json]
    end

    def self.add_tags_for_account(account_id, tags, current_user = nil, reason = nil, comment = nil, options = {})
      call_killbill :post,
                    "/1.0/kb/accounts/#{account_id}/tags?" + RestClient::Payload.generate(:tagList => tags.join(",")).to_s,
                    nil,
                    build_audit_headers(current_user, reason, comment, options)
    end

    def self.remove_tags_for_account(account_id, tags, current_user = nil, reason = nil, comment = nil, options = {})
      return if !tags.present? || tags.size == 0
      call_killbill :delete,
                    "/1.0/kb/accounts/#{account_id}/tags?" + RestClient::Payload.generate(:tagList => tags.join(",")).to_s,
                    build_audit_headers(current_user, reason, comment, options)
    end

    def self.set_tags_for_bundle(bundle_id, tags, current_user = nil, reason = nil, comment = nil, options = {})
      if tags.nil? || tags.empty?
      else
        call_killbill :post,
                      "/1.0/kb/bundles/#{bundle_id}/tags?" + RestClient::Payload.generate(:tag_list => tags.join(",")).to_s,
                      nil,
                      build_audit_headers(current_user, reason, comment, options)
      end
    end

    ############## CUSTOM FIELDS ##############

    def self.get_custom_fields(offset, limit, options = {})
      KillBillClient::Model::CustomField.find_in_batches offset, limit, options
    end

    def self.search_custom_fields(search_key, offset, limit, options = {})
      KillBillClient::Model::CustomField.find_in_batches_by_search_key search_key, offset, limit, options
    end

    def self.get_custom_fields_for_account(account_id, options = {})
      data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/customFields", options
      process_response(data, :multiple) { |json| Kaui::CustomField.new(json) }
    end

    ############## OVERDUE ##############

    def self.get_overdue_state_for_account(account_id, options = {})
      account = KillBillClient::Model::Account.new
      account.account_id = account_id
      account.overdue(options)
    end

    ############## ANALYTICS ##############

    def self.get_account_snapshot(account_id, options = {})
      data = call_killbill :get, "/plugins/killbill-analytics/#{account_id}", options
      process_response(data, :single) { |json| Kaui::BusinessSnapshot.new(json) }
    end

    def self.refresh_account(account_id, current_user = nil, reason = nil, comment = nil, options = {})
      call_killbill :put,
                    "/plugins/killbill-analytics/#{account_id}",
                    nil,
                    build_audit_headers(current_user, reason, comment, options)
    end

    def self.before_all
      methods.each do |method_name|
        method = method(method_name)
        (
        class << self;
          self
        end
        ).instance_eval {
          define_method(method_name) do |*args, &block|
            yield
            method.call(*args, &block)
          end
        }
      end
    end

    before_all { KillBillClient.url = Kaui.killbill_finder.call }
  end
end
