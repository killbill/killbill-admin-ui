require 'rest_client'

module Kaui
  module KillbillHelper

    def self.call_killbill(method, uri, *args)
      url = Kaui.killbill_finder.call + uri
      Rails.logger.info "Performing #{method} request to #{url}"
      response = RestClient.send(method.to_sym, url, *args)
      data = { :code => response.code }
      if response.code < 300 && response.body.present?
        data[:json] = JSON.parse(response.body)
      end
      # TODO: error handling
      data
    end

    ############## ACCOUNT ##############

    def self.get_account_timeline(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/timeline"
        process_response(data, :single) {|json| Kaui::AccountTimeline.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_account(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}"
        process_response(data, :single) {|json| Kaui::Account.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_account_by_external_key(external_key)
      begin
        data = call_killbill :get, "/1.0/kb/accounts?external_key=#{external_key}"
        process_response(data, :single) {|json| Kaui::Account.new(json) }
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

    def self.get_bundle_by_external_key(external_key)
      begin
        data = call_killbill :get, "/1.0/kb/bundles?external_key=#{external_key}"
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

    def self.get_bundles(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/bundles"
        process_response(data, :multiple) {|json| Kaui::Bundle.new(json) }

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
        puts subscriptions
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

    def self.create_subscription(subscription)
      begin
        subscription_data = Kaui::Subscription.camelize(subscription.to_hash)
        data = call_killbill :post,
                             "/1.0/kb/subscriptions",
                             ActiveSupport::JSON.encode(subscription_data, :root => false),
                             :content_type => "application/json",
                              "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                              "X-Killbill-Reason" => "Very special reason",
                              "X-Killbill-Comment" => "Very special comment"
        return data[:code] == 201
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.update_subscription(subscription)
      begin
        subscription_data = Kaui::Subscription.camelize(subscription.to_hash)
        data = call_killbill :put,
                             "/1.0/kb/subscriptions/#{subscription.subscription_id}",
                             ActiveSupport::JSON.encode(subscription_data, :root => false),
                             :content_type => :json,
                             "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                             "X-Killbill-Reason" => "Very special reason",
                             "X-Killbill-Comment" => "Very special comment"
        return data[:code] == 200
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.reinstate_subscription(subscription_id)
      begin
        data = call_killbill :put,
                             "/1.0/subscriptions/#{subscription_id}/uncancel",
                             :content_type => :json,
                             "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                             "X-Killbill-Reason" => "Very special reason",
                             "X-Killbill-Comment" => "Very special comment"
        return data[:code] == 200
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.delete_subscription(subscription_id)
      begin
        data = call_killbill :delete,
                             "/1.0/kb/subscriptions/#{subscription_id}",
                             "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                             "X-Killbill-Reason" => "Very special reason",
                             "X-Killbill-Comment" => "Very special comment"
        return data[:code] == 200
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

    ############## CATALOG ##############

    def self.get_available_addons
      begin
        data = call_killbill :get, "/1.0/catalog/availableAddons"
        return data[:json]
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## PAYMENT ##############

    # def self.get_payment_attempt(external_key, invoice_id, payment_id)
    #   payment_attempts = get_payment_attempts(external_key, invoice_id)
    #   payment_attempts.each do |payment_attempt|
    #     return payment_attempt if payment_attempt.payment_id == payment_id
    #   end
    #   nil
    # end

    # def self.get_payment_attempts(external_key, invoice_id)
    #   begin
    #     #TODO: add if needed
    #     if data.nil?
    #       []
    #     else
    #       data.collect {|item| Kaui::PaymentAttempt.new(item) }
    #     end
    #   rescue => e
    #     puts "#{$!}\n\t" + e.backtrace.join("\n\t")
    #     []
    #   end
    # end

    def self.get_payment(invoice_id, payment_id)
      payments = get_payments(invoice_id)
      payments.each do |payment|
        return payment if payment.payment_id == payment_id
      end
      nil
    end

    def self.get_payments(invoice_id)
      begin
        data = call_killbill :get, "/1.0/kb/invoices/#{invoice_id}/payments"
        process_response(data, :single) {|json| Kaui::Payment.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
        []
      end
    end

    ############## PAYMENT METHOD ##############

    def self.delete_payment_method(account_id, payment_method_id)
      begin
        call_killbill :delete, "/1.0/accounts/#{account_id}/paymentMethods/#{payment_method_id}"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_payment_methods(account_id)
      begin
        data = call_killbill :get, "/1.0/accounts/#{account_id}/paymentMethods"
        process_response(data, :single) {|json| Kaui::PaymentMethod.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## REFUND ##############

    def self.get_refunds_for_payment(payment_id)
      begin
        call_killbill :get, "/1.0/kb/payments/#{payment_id}/refunds"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.create_refund(payment_id, refund, reason, comment)
      begin
        refund_data = Kaui::Refund.camelize(refund.to_hash)
        data = call_killbill :post,
                      "/1.0/kb/payments/#{payment_id}/refunds",
                      ActiveSupport::JSON.encode(refund_data, :root => false),
                      :content_type => "application/json",
                      "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                      "X-Killbill-Reason" => "#{reason}",
                      "X-Killbill-Comment" => "#{comment}"
        return response[:code] == 201
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## CHARGEBACK ##############

    def self.get_chargebacks_for_payment(payment_id)
      begin
        data = call_killbill :get, "/1.0/kb/chargebacks/payments/#{payment_id}"
        process_response(data, :single) {|json| Kaui::Chargeback.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.create_chargeback(chargeback, reason, comment)
      begin
        chargeback_data = Kaui::Refund.camelize(chargeback.to_hash)
        data = call_killbill :post,
                             "/1.0/kb/chargebacks",
                             ActiveSupport::JSON.encode(chargeback_data, :root => false),
                             :content_type => "application/json",
                             "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                             "X-Killbill-Reason" => "#{reason}",
                             "X-Killbill-Comment" => "#{comment}"
        return data[:code] == 201
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## TAG ##############

    def self.get_tag_definitions
      begin
        data = call_killbill :get, "/1.0/kb/tagDefinitions"
        process_response(data, :single) {|json| Kaui::Tag.new(json) }
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
        []
      end
    end

    def self.get_tags_for_account(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/tags"
        return data[:json]
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


    def self.set_tags_for_account(account_id, tags)
      begin
        if tags.nil? || tags.empty?
        else
          data = call_killbill :post,
                               "/1.0/kb/accounts/#{account_id}/tags?" + RestClient::Payload.generate(:tag_list => tags.join(",")).to_s,
                               nil,
                               "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                               "X-Killbill-Reason" => "Very special reason",
                               "X-Killbill-Comment" => "Very special comment"
          return data[:code] == 201
        end
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.set_tags_for_bundle(bundle_id, tags)
      begin
        if tags.nil? || tags.empty?
        else
          data = call_killbill :post,
                               "/1.0/kb/bundles/#{bundle_id}/tags?" + RestClient::Payload.generate(:tag_list => tags.join(",")).to_s,
                               nil,
                               "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                               "X-Killbill-Reason" => "Very special reason",
                               "X-Killbill-Comment" => "Very special comment"
          return data[:code] == 201
        end
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    private

    def self.process_response(response, arity, &block)
      if response.nil? || response[:json].nil?
        arity == :single ? nil : []
      elsif block_given?
        arity == :single ? yield(response[:json]) : response[:json].collect {|item| yield(item) }
      else
        response[:json]
      end
    end

  end
end
