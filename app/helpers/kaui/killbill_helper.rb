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
