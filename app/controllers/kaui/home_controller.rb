# frozen_string_literal: true

module Kaui
  class HomeController < Kaui::EngineController
    QUERY_PARSE_REGEX = ['FIND:(?<object_type>.*) BY:(?<search_by>.*) FOR:(?<search_for>.*) ONLY_FIRST:(?<fast>.*)',
                         'FIND:(?<object_type>.*) BY:(?<search_by>.*) FOR:(?<search_for>.*)',
                         'FIND:(?<object_type>.*) FOR:(?<search_for>.*) ONLY_FIRST:(?<fast>.*)',
                         'FIND:(?<object_type>.*) FOR:(?<search_for>.*)'].freeze

    SIMPLE_PARSE_REGEX = '(?<search_for>.*)'

    def index
      @search_query = params[:q]
    end

    def search
      object_type, search_query = splitting_new_search(params[:q])

      cached_options_for_klient = options_for_klient
      send("#{object_type}_search", search_query, nil, 0, cached_options_for_klient)
    end

    private

    def splitting_new_search(search_query)
      search_query.split(':').map(&:strip)
    end

    def account_search(search_query, search_by = nil, fast = 0, options = {})
      if search_by == 'ID'
        begin
          account = Kaui::Account.find_by_id(search_query, false, false, options)
          redirect_to account_path(account.account_id) and return
        rescue KillBillClient::API::NotFound => _e
          search_error("No account matches \"#{search_query}\"")
        end
      elsif search_by == 'EXTERNAL_KEY'
        begin
          account = Kaui::Account.find_by_external_key(search_query, false, false, options)
          redirect_to account_path(account.account_id) and return
        rescue KillBillClient::API::NotFound => _e
          search_error("No account matches \"#{search_query}\"")
        end
      else
        account = Kaui::Account.list_or_search(search_query, 0, 1, options).first
        if account.blank?
          search_error("No account matches \"#{search_query}\"")
        elsif true?(fast)
          redirect_to account_path(account.account_id) and return
        else
          redirect_to accounts_path(q: search_query, fast:) and return
        end
      end
    end

    def invoice_search(search_query, search_by = nil, fast = 0, options = {})
      case search_by
      when 'ID'
        begin
          invoice = Kaui::Invoice.find_by_id(search_query, false, 'NONE', options)
          redirect_to account_invoice_path(invoice.account_id, invoice.invoice_id) and return
        rescue KillBillClient::API::NotFound => _e
          search_error("No invoice matches \"#{search_query}\"")
        end
      when 'EXTERNAL_KEY'
        unsupported_search_field('INVOICE', search_by)
      when 'NUMBER'
        begin
          invoice = Kaui::Invoice.find_by_number(search_query, false, 'NONE', options)
          redirect_to account_invoice_path(invoice.account_id, invoice.invoice_id) and return
        rescue KillBillClient::API::NotFound, KillBillClient::API::BadRequest => _e
          search_error("No invoice matches \"#{search_query}\"")
        end
      else
        invoice = Kaui::Invoice.list_or_search(search_query, 0, 1, options).first
        if invoice.blank?
          begin
            invoice = Kaui::Invoice.find_by_invoice_item_id(search_query, false, 'NONE', options)
            redirect_to account_invoice_path(invoice.account_id, invoice.invoice_id) and return
          rescue KillBillClient::API::NotFound => _e
            search_error("No invoice matches \"#{search_query}\"")
          end
        elsif true?(fast)
          redirect_to account_invoice_path(invoice.account_id, invoice.invoice_id) and return
        else
          redirect_to account_invoices_path(account_id: invoice.account_id, q: search_query, fast:) and return
        end
      end
    end

    def payment_search(search_query, search_by = nil, fast = 0, options = {})
      if search_by == 'ID'
        begin
          payment = Kaui::Payment.find_by_id(search_query, false, false, options)
          redirect_to account_payment_path(payment.account_id, payment.payment_id) and return
        rescue KillBillClient::API::NotFound => _e
          search_error("No payment matches \"#{search_query}\"")
        end
      elsif search_by == 'EXTERNAL_KEY'
        begin
          payment = Kaui::Payment.find_by_external_key(search_query, false, false, options)
          redirect_to account_payment_path(payment.account_id, payment.payment_id) and return
        rescue KillBillClient::API::NotFound => _e
          search_error("No payment matches \"#{search_query}\"")
        end
      else
        payment = Kaui::Payment.list_or_search(search_query, 0, 1, options).first
        if payment.blank?
          search_error("No payment matches \"#{search_query}\"")
        elsif true?(fast)
          redirect_to account_payment_path(payment.account_id, payment.payment_id) and return
        else
          redirect_to account_payments_path(account_id: payment.account_id, q: search_query, fast:) and return
        end
      end
    end

    def transaction_search(search_query, search_by = nil, _fast = 0, options = {})
      if search_by.blank? || search_by == 'ID'
        begin
          payment = Kaui::Payment.find_by_transaction_id(search_query, false, true, [], 'NONE', options)
          redirect_to account_payment_path(payment.account_id, payment.payment_id) and return
        rescue KillBillClient::API::NotFound => _e
          search_error("No transaction matches \"#{search_query}\"")
        end
      else
        begin
          payment = Kaui::Payment.find_by_transaction_external_key(search_query, false, true, [], 'NONE', options)
          redirect_to account_payment_path(payment.account_id, payment.payment_id) and return
        rescue KillBillClient::API::NotFound => _e
          search_error("No transaction matches \"#{search_query}\"")
        end
      end
    end

    def bundle_search(search_query, search_by = nil, _fast = 0, options = {})
      if search_by == 'ID'
        begin
          bundle = Kaui::Bundle.find_by_id(search_query, options)
          redirect_to kaui_engine.account_bundles_path(bundle.account_id)
        rescue KillBillClient::API::NotFound => _e
          search_error("No bundle matches \"#{search_query}\"")
        end
      elsif search_by == 'EXTERNAL_KEY'
        begin
          bundle = Kaui::Bundle.find_by_external_key(search_query, false, options)
          redirect_to kaui_engine.account_bundles_path(bundle.account_id) and return
        rescue KillBillClient::API::NotFound => _e
          search_error("No bundle matches \"#{search_query}\"")
        end
      else
        bundle = Kaui::Bundle.list_or_search(search_query, 0, 1, options).first
        if bundle.blank?
          search_error("No bundle matches \"#{search_query}\"")
        else
          redirect_to kaui_engine.account_bundles_path(bundle.account_id)
        end
      end
    end

    def credit_search(search_query, search_by = nil, _fast = 0, options = {})
      if search_by.blank? || search_by == 'ID'
        begin
          credit = Kaui::Credit.find_by_id(search_query, options)
          redirect_to account_invoice_path(credit.account_id, credit.invoice_id) and return
        rescue KillBillClient::API::NotFound => _e
          search_error("No credit matches \"#{search_query}\"")
        end
      else
        unsupported_search_field('CREDIT', search_by)
      end
    end

    def custom_field_search(search_query, search_by = nil, fast = 0, options = {})
      if search_by.blank? || search_by == 'ID'
        custom_field = Kaui::CustomField.list_or_search(search_query, 0, 1, options)
        if custom_field.blank?
          search_error("No custom field matches \"#{search_query}\"")
        else
          redirect_to custom_fields_path(q: search_query, fast:)
        end
      else
        unsupported_search_field('CUSTOM FIELD', search_by)
      end
    end

    def invoice_payment_search(search_query, search_by = nil, _fast = 0, options = {})
      if search_by.blank? || search_by == 'ID'
        begin
          invoice_payment = Kaui::InvoicePayment.find_safely_by_id(search_query, options)
          redirect_to account_payment_path(invoice_payment.account_id, invoice_payment.payment_id) and return
        rescue KillBillClient::API::NotFound => _e
          search_error("No invoice payment matches \"#{search_query}\"")
        end
      else
        unsupported_search_field('INVOICE PAYMENT', search_by)
      end
    end

    def subscription_search(search_query, search_by = nil, _fast = 0, options = {})
      if search_by.blank? || search_by == 'ID'
        begin
          subscription = Kaui::Subscription.find_by_id(search_query, 'NONE', options)
          redirect_to account_bundles_path(subscription.account_id) and return
        rescue KillBillClient::API::NotFound => _e
          search_error("No subscription matches \"#{search_query}\"")
        end
      else
        unsupported_search_field('SUBSCRIPTION', search_by)
      end
    end

    def tag_search(search_query, search_by = nil, fast = 0, options = {})
      if search_by.blank? || search_by == 'ID'
        tag = Kaui::Tag.list_or_search(search_query, 0, 1, options)
        if tag.blank?
          search_error("No tag matches \"#{search_query}\"")
        else
          redirect_to tags_path(q: search_query, fast:)
        end
      else
        unsupported_search_field('TAG', search_by)
      end
    end

    def tag_definition_search(search_query, search_by = nil, fast = 0, options = {})
      if search_by == 'ID'
        begin
          Kaui::TagDefinition.find_by_id(search_query, 'NONE', options)
          redirect_to tag_definitions_path(q: search_query, fast:)
        rescue KillBillClient::API::NotFound => _e
          search_error("No tag definition matches \"#{search_query}\"")
        end
      elsif search_by == 'EXTERNAL_KEY'
        unsupported_search_field('TAG DEFINITION', search_by)
      else
        tag_definition = Kaui::TagDefinition.find_by_name(search_query, 'NONE', options)
        if tag_definition.blank?
          begin
            Kaui::TagDefinition.find_by_id(search_query, 'NONE', options)
            redirect_to tag_definitions_path(q: search_query, fast:) and return
          rescue KillBillClient::API::NotFound => _e
            search_error("No tag definition matches \"#{search_query}\"")
          end
        else
          redirect_to tag_definitions_path(q: search_query, fast:)
        end
      end
    end

    def unsupported_search_field(object_type, object_field)
      field_name = object_field.gsub('_', ' ')
      search_error("\"#{object_type}\": Search by \"#{field_name}\" is not supported.")
    end

    def search_error(message)
      flash[:error] = message
      redirect_to kaui_engine.home_path
    end

    def parse_query(query)
      statements, simple_regex_used = regex_parse_query(query)

      object_type = begin
        statements[:object_type].strip.downcase
      rescue StandardError
        'account'
      end
      search_for = statements[:search_for].strip
      search_by = begin
        statements[:search_by].strip.upcase
      rescue StandardError
        simple_regex_used && uuid?(search_for) ? 'ID' : nil
      end
      fast = begin
        statements[:fast]
      rescue StandardError
        '0'
      end

      search_error("\"#{search_by}\" is not a valid search by value") if !search_by.blank? && !search_by.in?(Kaui::ObjectHelper::ADVANCED_SEARCH_OBJECT_FIELDS)

      [object_type, search_for, search_by, fast]
    end

    def regex_parse_query(query)
      statements = nil
      simple_regex_used = false
      QUERY_PARSE_REGEX.each do |query_regex|
        regex_exp = Regexp.new(query_regex, true)
        statements = regex_exp.match(query)
        break unless statements.nil?
      end

      if statements.nil?
        regex_exp = Regexp.new(SIMPLE_PARSE_REGEX, true)
        statements = regex_exp.match(query)
        simple_regex_used = true
      end

      [statements, simple_regex_used]
    end

    def true?(statement)
      [1, '1', true, 'true'].include?(statement.instance_of?(String) ? statement.downcase : statement)
    end

    def uuid?(value)
      value =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
    end
  end
end
