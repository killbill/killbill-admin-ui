require 'rest_client'

module Kaui
  module KillbillHelper

    def self.call_killbill(method, uri, *args)
      url = Kaui.killbill_finder.call + uri
      Rails.logger.info "Performing #{method} request to #{url}"
      response = RestClient.send(method.to_sym, url, *args)
      data = { :code => response.code }
      if response.code < 300 && response.body.present?
        if response.headers[:content_type] =~ /application\/json.*/
          data[:json] = JSON.parse(response.body)
        else
          data[:body] = response.body
        end
      end
      # TODO: error handling
      data
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

    def self.get_account_timeline(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/timeline?audit=MINIMAL"
        process_response(data, :single) {|json| Kaui::AccountTimeline.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_account(account_id, with_balance=false)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}?accountWithBalance=#{with_balance}"
        process_response(data, :single) {|json| Kaui::Account.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_account_by_external_key(external_key, with_balance=false)
      begin
        data = call_killbill :get, "/1.0/kb/accounts?externalKey=#{external_key}&accountWithBalance=#{with_balance}"
        process_response(data, :single) {|json| Kaui::Account.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
        "#{e.message} #{e.response}"
      end
    end

    def self.get_account_by_bundle_id(bundle_id)
      begin
        bundle = get_bundle(bundle_id)
        account = get_account(bundle.account_id)
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## BUNDLE ##############

    def self.get_bundles(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/bundles"
        process_response(data, :multiple) {|json| Kaui::Bundle.new(json) }
      rescue RestClient::BadRequest
        []
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_bundle_by_external_key(account_id, external_key)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/bundles?externalKey=#{external_key}"
        process_response(data, :single) {|json| Kaui::Bundle.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_bundle(bundle_id)
      begin
        data = call_killbill :get, "/1.0/kb/bundles/#{bundle_id}"
        process_response(data, :single) {|json| Kaui::Bundle.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.transfer_bundle(bundle_id, new_account_id, cancel_immediately = false, transfer_addons = true, current_user = nil, reason = nil, comment = nil)
      begin
        data = call_killbill :put,
                             "/1.0/kb/bundles/#{bundle_id}?cancelImmediately=#{cancel_immediately}&transferAddOn=#{transfer_addons}",
                             ActiveSupport::JSON.encode("accountId" => new_account_id),
                             :content_type => :json,
                             "X-Killbill-CreatedBy" => current_user,
                             "X-Killbill-Reason" => "#{reason}",
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300

      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## SUBSCRIPTION ##############

    def self.get_subscriptions_for_bundle(bundle_id)
      begin
        data = call_killbill :get, "/1.0/kb/bundles/#{bundle_id}/subscriptions"
        process_response(data, :multiple) {|json| Kaui::Subscription.new(json) }
      rescue RestClient::BadRequest
        []
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_subscriptions(account_id)
      begin
        subscriptions = []
        bundles = get_bundles(account_id)
        bundles.each do |bundle|
          subscriptions += get_subscriptions_for_bundle(bundle.bundle_id)
        end
        subscriptions
      rescue RestClient::BadRequest
        []
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_subscription(subscription_id)
      begin
        data = call_killbill :get, "/1.0/kb/subscriptions/#{subscription_id}"
        process_response(data, :single) {|json| Kaui::Subscription.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.create_subscription(subscription, current_user = nil, reason = nil, comment = nil)
      begin
        subscription_data = Kaui::Subscription.camelize(subscription.to_hash)
        # We don't want to pass events
        subscription_data.delete(:events)
        data = call_killbill :post,
                             "/1.0/kb/subscriptions",
                             ActiveSupport::JSON.encode(subscription_data, :root => false),
                             :content_type => "application/json",
                              "X-Killbill-CreatedBy" => current_user,
                              "X-Killbill-Reason" => "#{reason}",
                              "X-Killbill-Comment" => "#{comment}"
        return data[:code] == 201
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.update_subscription(subscription, requested_date = nil, current_user = nil, reason = nil, comment = nil)
      begin
        subscription_data = Kaui::Subscription.camelize(subscription.to_hash)
        date_param = "?requestedDate=" + requested_date.to_s unless requested_date.blank?

        data = call_killbill :put,
                             "/1.0/kb/subscriptions/#{subscription.subscription_id}#{date_param}",
                             ActiveSupport::JSON.encode(subscription_data, :root => false),
                             :content_type => :json,
                             "X-Killbill-CreatedBy" => current_user,
                             "X-Killbill-Reason" => "#{reason}",
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.reinstate_subscription(subscription_id, current_user = nil, reason = nil, comment = nil)
      begin
        data = call_killbill :put,
                             "/1.0/kb/subscriptions/#{subscription_id}/uncancel",
                             "",
                             :content_type => :json,
                             "X-Killbill-CreatedBy" => current_user,
                             "X-Killbill-Reason" => "#{reason}",
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.delete_subscription(subscription_id, current_user = nil, reason = nil, comment = nil)
      begin
        data = call_killbill :delete,
                             "/1.0/kb/subscriptions/#{subscription_id}",
                             "X-Killbill-CreatedBy" => current_user,
                             "X-Killbill-Reason" => "#{reason}",
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## INVOICE ##############

    def self.get_invoice(invoice_id)
      begin
        data = call_killbill :get, "/1.0/kb/invoices/#{invoice_id}?withItems=true"
        process_response(data, :single) {|json| Kaui::Invoice.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
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
      begin
        data = call_killbill :get, "/1.0/kb/invoices/#{invoice_id}/html"
        data[:body] if data.present?
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.adjust_invoice(invoice_item, current_user = nil, reason = nil, comment = nil)
      begin
        invoice_data = Kaui::InvoiceItem.camelize(invoice_item.to_hash)
        data = call_killbill :post,
                             "/1.0/kb/invoices/#{invoice_item.invoice_id}",
                             ActiveSupport::JSON.encode(invoice_data, :root => false),
                             :content_type => :json,
                             "X-Killbill-CreatedBy" => current_user,
                             "X-Killbill-Reason" => "#{reason}",
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.create_charge(charge, requested_date, current_user = nil, reason = nil, comment = nil)
      begin
        charge_data = Kaui::Charge.camelize(charge.to_hash)
        date_param = "?requestedDate=" + requested_date unless requested_date.blank?

        if charge.invoice_id.present?
          data = call_killbill :post,
                               "/1.0/kb/invoices/#{charge.invoice_id}/charges#{date_param}",
                               ActiveSupport::JSON.encode(charge_data, :root => false),
                               :content_type => "application/json",
                               "X-Killbill-CreatedBy" => current_user,
                               "X-Killbill-Reason" => extract_reason_code(reason),
                               "X-Killbill-Comment" => "#{comment}"
        else
          data = call_killbill :post,
                   "/1.0/kb/invoices/charges#{date_param}",
                   ActiveSupport::JSON.encode(charge_data, :root => false),
                   :content_type => "application/json",
                   "X-Killbill-CreatedBy" => current_user,
                   "X-Killbill-Reason" => extract_reason_code(reason),
                   "X-Killbill-Comment" => "#{comment}"
        end
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## CATALOG ##############

    def self.get_available_addons(base_product_name)
      begin
        data = call_killbill :get, "/1.0/kb/catalog/availableAddons?baseProductName=#{base_product_name}"
        if data.has_key?(:json)
          data[:json].inject({}) {|catalog_hash, item| catalog_hash.merge!(item["planName"] => item) }
        end
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_available_base_plans()
      begin
        data = call_killbill :get, "/1.0/kb/catalog/availableBasePlans"
        if data.has_key?(:json)
          data[:json].inject({}) {|catalog_hash, item| catalog_hash.merge!(item["planName"] => item) }
        end
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## PAYMENT ##############

    def self.get_payment(payment_id)
      begin
        data = call_killbill :get, "/1.0/kb/payments/#{payment_id}"
        process_response(data, :single) { |json| Kaui::Payment.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_payments(invoice_id)
      begin
        data = call_killbill :get, "/1.0/kb/invoices/#{invoice_id}/payments"
        response_data = process_response(data, :multiple) {|json| Kaui::Payment.new(json) }
        return response_data
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
        []
      end
    end

    def self.create_payment(payment, external, current_user = nil, reason = nil, comment = nil)
      begin
        payment_data = Kaui::Payment.camelize(payment.to_hash)

        if payment.invoice_id.present?
          data = call_killbill :post,
                               "/1.0/kb/invoices/#{payment.invoice_id}/payments?externalPayment=#{external}",
                               ActiveSupport::JSON.encode(payment_data, :root => false),
                               :content_type => "application/json",
                               "X-Killbill-CreatedBy" => current_user,
                               "X-Killbill-Reason" => extract_reason_code(reason),
                               "X-Killbill-Comment" => "#{comment}"
          return data[:code] < 300
        else
          return false
        end
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## PAYMENT METHOD ##############

    def self.delete_payment_method(payment_method_id, current_user = nil, reason = nil, comment = nil)
      begin
        call_killbill :delete,
                      "/1.0/kb/paymentMethods/#{payment_method_id}",
                      "X-Killbill-CreatedBy" => current_user,
                      "X-Killbill-Reason" => "#{reason}",
                      "X-Killbill-Comment" => "#{comment}"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_payment_methods(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/paymentMethods?withPluginInfo=true"
        process_response(data, :multiple) {|json| Kaui::PaymentMethod.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_payment_method(payment_method_id)
      begin
        data = call_killbill :get, "/1.0/kb/paymentMethods/#{payment_method_id}?withPluginInfo=true"
        process_response(data, :single) {|json| Kaui::PaymentMethod.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.set_payment_method_as_default(account_id, payment_method_id, current_user = nil, reason = nil, comment = nil)
      begin
        data = call_killbill :put, "/1.0/kb/accounts/#{account_id}/paymentMethods/#{payment_method_id}/setDefault",
                                   "",
                                   :content_type => :json,
                                   "X-Killbill-CreatedBy" => current_user,
                                   "X-Killbill-Reason" => extract_reason_code(reason),
                                   "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.add_payment_method(payment_method, current_user = nil, reason = nil, comment = nil)
      payment_method_data = Kaui::Refund.camelize(payment_method.to_hash)
      begin
        data = call_killbill :post, "/1.0/kb/accounts/#{payment_method.account_id}/paymentMethods?isDefault=#{payment_method.is_default}",
                                    ActiveSupport::JSON.encode(payment_method_data, :root => false),
                                    :content_type => :json,
                                    "X-Killbill-CreatedBy" => current_user,
                                    "X-Killbill-Reason" => extract_reason_code(reason),
                                    "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## REFUND ##############

    def self.get_refund(refund_id)
      begin
        data = call_killbill :get, "/1.0/kb/refunds/#{refund_id}"
        process_response(data, :single) { |json| Kaui::Refund.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_refunds_for_payment(payment_id)
      begin
        data = call_killbill :get, "/1.0/kb/payments/#{payment_id}/refunds"
        process_response(data, :multiple) {|json| Kaui::Refund.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.create_refund(payment_id, refund, current_user = nil, reason = nil, comment = nil)
      begin
        refund_data = Kaui::Refund.camelize(refund.to_hash)

        data = call_killbill :post,
                      "/1.0/kb/payments/#{payment_id}/refunds",
                      ActiveSupport::JSON.encode(refund_data, :root => false),
                      :content_type => "application/json",
                      "X-Killbill-CreatedBy" => current_user,
                      "X-Killbill-Reason" => extract_reason_code(reason),
                      "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## CHARGEBACK ##############

    def self.get_chargebacks_for_payment(payment_id)
      begin
        data = call_killbill :get, "/1.0/kb/chargebacks/payments/#{payment_id}"
        process_response(data, :multiple) {|json| Kaui::Chargeback.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.create_chargeback(chargeback, current_user = nil, reason = nil, comment = nil)
      begin
        chargeback_data = Kaui::Refund.camelize(chargeback.to_hash)

        data = call_killbill :post,
                             "/1.0/kb/chargebacks",
                             ActiveSupport::JSON.encode(chargeback_data, :root => false),
                             :content_type => "application/json",
                             "X-Killbill-CreatedBy" => current_user,
                             "X-Killbill-Reason" => extract_reason_code(reason),
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## CREDIT ##############

    def self.create_credit(credit, current_user = nil, reason = nil, comment = nil)
      begin
        credit_data = Kaui::Credit.camelize(credit.to_hash)
        data = call_killbill :post,
                             "/1.0/kb/credits",
                             ActiveSupport::JSON.encode(credit_data, :root => false),
                             :content_type => "application/json",
                             "X-Killbill-CreatedBy" => current_user,
                             "X-Killbill-Reason" => extract_reason_code(reason),
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## TAG ##############

    def self.get_tag_definitions
      begin
        data = call_killbill :get, "/1.0/kb/tagDefinitions"
        process_response(data, :multiple) { |json| Kaui::TagDefinition.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
        []
      end
    end

    def self.get_tag_definition(tag_definition_id)
      begin
        data = call_killbill :get, "/1.0/kb/tagDefinitions/#{tag_definition_id}"
        process_response(data, :single) { |json| Kaui::TagDefinition.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
        []
      end
    end

    def self.create_tag_definition(tag_definition, current_user = nil, reason = nil, comment = nil)
      begin
        tag_definition_data = Kaui::TagDefinition.camelize(tag_definition.to_hash)
        data = call_killbill :post,
                             "/1.0/kb/tagDefinitions",
                             ActiveSupport::JSON.encode(tag_definition_data, :root => false),
                             :content_type => "application/json",
                             "X-Killbill-CreatedBy" => current_user,
                             "X-Killbill-Reason" => extract_reason_code(reason),
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.delete_tag_definition(tag_definition_id, current_user = nil, reason = nil, comment = nil)
      begin
        data = call_killbill :delete,
                             "/1.0/kb/tagDefinitions/#{tag_definition_id}",
                             "X-Killbill-CreatedBy" => current_user,
                             "X-Killbill-Reason" => "#{reason}",
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_tags_for_account(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/tags"
        process_response(data, :multiple) { |json| Kaui::Tag.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_tags_for_bundle(bundle_id)
      begin
        data = call_killbill :get, "/1.0/kb/bundles/#{bundle_id}/tags"
        return data[:json]
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end


    def self.add_tags_for_account(account_id, tags, current_user = nil, reason = nil, comment = nil)
      return true if !tags.present? || tags.size == 0
      begin
        data = call_killbill :post,
                             "/1.0/kb/accounts/#{account_id}/tags?" + RestClient::Payload.generate(:tagList => tags.join(",")).to_s,
                             nil,
                             "X-Killbill-CreatedBy" => current_user,
                             "X-Killbill-Reason" => "#{reason}",
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] == 201
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.remove_tags_for_account(account_id, tags, current_user = nil, reason = nil, comment = nil)
      return true if !tags.present? || tags.size == 0
      begin
        data = call_killbill :delete,
                             "/1.0/kb/accounts/#{account_id}/tags?" + RestClient::Payload.generate(:tagList => tags.join(",")).to_s,
                             "X-Killbill-CreatedBy" => current_user,
                             "X-Killbill-Reason" => "#{reason}",
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] < 300
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.set_tags_for_bundle(bundle_id, tags, current_user = nil, reason = nil, comment = nil)
      begin
        if tags.nil? || tags.empty?
        else
          data = call_killbill :post,
                               "/1.0/kb/bundles/#{bundle_id}/tags?" + RestClient::Payload.generate(:tag_list => tags.join(",")).to_s,
                               nil,
                               "X-Killbill-CreatedBy" => current_user,
                               "X-Killbill-Reason" => "#{reason}",
                               "X-Killbill-Comment" => "#{comment}"
          return data[:code] == 201
        end
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

  end
end
