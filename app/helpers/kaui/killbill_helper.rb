require 'rest_client'

module Kaui
  module KillbillHelper

    def self.call_killbill(method, uri, *args)
      url = Kaui.killbill_finder.call + uri
      Rails.logger.info "Performing #{method} request to #{url}"
      response = RestClient.send(method.to_sym, url, *args)
      if response.code < 300
        return JSON.parse(response.body) if response.body.present?
      end
      # TODO: error handling
      nil
    end

    ############## ACCOUNT ##############

    def self.get_account_timeline(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/timeline"
        data.nil? ? nil : Kaui::AccountTimeline.new(data)
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_account(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}"
        data.nil? ? nil : Kaui::Account.new(data)
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_account_by_external_key(external_key)
      begin
        data = call_killbill :get, "/1.0/kb/accounts?external_key=#{external_key}"
        data.nil? ? nil : Kaui::Account.new(data)
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## BUNDLE ##############

    def self.get_bundles(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/bundles"
        if data.nil?
          []
        else
          data.collect {|item| Kaui::Bundle.new(item) }
        end
      rescue RestClient::BadRequest
        []
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_bundle_by_external_key(external_key)
      begin
        data = call_killbill :get, "/1.0/kb/bundles?external_key=#{external_key}"
        data.nil? ? nil : Kaui::Bundle.new(data)
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_bundle(bundle_id)
      begin
        data = call_killbill :get, "/1.0/kb/bundles/#{bundle_id}"
        data.nil? ? nil : Kaui::Bundle.new(data)
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_bundles(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/bundles"
        if data.nil?
          []
        else
          data.collect {|item| Kaui::Bundle.new(item) }
        end
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## SUBSCRIPTION ##############

    def self.get_subscriptions_for_bundle(bundle_id)
      begin
        data = call_killbill :get, "/1.0/kb/bundles/#{bundle_id}/subscriptions"
        if data.nil?
          []
        else
          data.collect {|item| Kaui::Subscription.new(item) }
        end
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
        data.nil? ? nil : Kaui::Subscription.new(data)
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.create_subscription(subscription)
      begin
        data = Kaui::Subscription.camelize(subscription.to_hash)
        call_killbill :post,
                      "/1.0/kb/subscriptions",
                      ActiveSupport::JSON.encode(subscription, :root => false),
                      :content_type => "application/json",
                      "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                      "X-Killbill-Reason" => "Very special reason",
                      "X-Killbill-Comment" => "Very special comment"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.update_subscription(subscription)
      begin
        data = Kaui::Subscription.camelize(subscription.to_hash)
        call_killbill :put,
                      "/1.0/kb/subscriptions/#{subscription.subscription_id}", 
                      ActiveSupport::JSON.encode(data, :root => false),
                      :content_type => :json,
                      "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                      "X-Killbill-Reason" => "Very special reason",
                      "X-Killbill-Comment" => "Very special comment"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.reinstate_subscription(subscription_id)
      begin
        call_killbill :put, 
                      "/1.0/subscriptions/#{subscription_id}/uncancel",
                      :content_type => :json,
                      "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                      "X-Killbill-Reason" => "Very special reason",
                      "X-Killbill-Comment" => "Very special comment"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.delete_subscription(subscription_id)
      begin
        call_killbill :delete,
                      "/1.0/kb/subscriptions/#{subscription_id}", 
                      "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                      "X-Killbill-Reason" => "Very special reason",
                      "X-Killbill-Comment" => "Very special comment"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.create_addon(subscription_id)
      begin
        call_killbill :post, "/1.0/kb/payments/#{payment_id}/chargebacks"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end      
    
    ############## INVOICE ##############

    def self.get_invoice(invoice_id)
      begin
        data = call_killbill :get, "/1.0/kb/invoices/#{invoice_id}?withItems=true"
        data.nil? ? nil : Kaui::Invoice.new(data)
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end
  
    ############## CATALOG ##############

    def self.get_available_addons
      begin
        call_killbill :get, "/1.0/catalog"
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
        if data.nil?
          []
        else
          data.collect {|item| Kaui::Payment.new(item) }
        end
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
        if data.nil?
          []
        else
          data.collect { |item| Kaui::PaymentMethod.new(item) }
        end
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

    def self.create_refund(payment_id)
      begin
        # TODO: add handling when implemented
        #call_killbill :post, "/1.0/kb/payments/#{payment_id}/refunds"
      rescue
      end
    end

    ############## CHARGEBACK ##############

    def self.get_chargebacks_for_payment(payment_id)
      begin
        call_killbill :get, "/1.0/kb/payments/#{payment_id}/chargebacks"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.create_chargeback(payment_id)
      begin
        call_killbill :post, "/1.0/kb/payments/#{payment_id}/chargebacks"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    ############## TAG ############## 

    def self.get_tag_definitions
      begin
        data = call_killbill :get, "/1.0/kb/tagDefinitions"
        if data.nil?
          []
        else
          data.collect {|item| Kaui::Tag.new(item) }
        end
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
        []
      end
    end

    def self.get_tags_for_account(account_id)
      begin
        data = call_killbill :get, "/1.0/kb/accounts/#{account_id}/tags"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.get_tags_for_bundle(bundle_id)
      begin
        data = call_killbill :get, "/1.0/kb/bundles/#{bundle_id}/tags"
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end


    def self.set_tags_for_account(account_id, tags)
      begin
        if tags.nil? || tags.empty?
        else
          call_killbill :post,
                        "/1.0/kb/accounts/#{account_id}/tags?" + RestClient::Payload.generate(:tag_list => tags.join(",")).to_s,
                        nil,
                        "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                        "X-Killbill-Reason" => "Very special reason",
                        "X-Killbill-Comment" => "Very special comment"
        end
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

    def self.set_tags_for_bundle(bundle_id, tags)
      begin
        if tags.nil? || tags.empty?
        else
          call_killbill :post,
                        "/1.0/kb/bundles/#{bundle_id}/tags?" + RestClient::Payload.generate(:tag_list => tags.join(",")).to_s,
                        nil,
                        "X-Killbill-CreatedBy" => Kaui.current_user.call.to_s,
                        "X-Killbill-Reason" => "Very special reason",
                        "X-Killbill-Comment" => "Very special comment"
        end
      rescue => e
        puts "#{$!}\n\t" + e.backtrace.join("\n\t")
      end
    end

  end
end
