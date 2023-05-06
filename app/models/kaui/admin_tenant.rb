# frozen_string_literal: true

module Kaui
  class AdminTenant < KillBillClient::Model::Tenant
    class << self
      def upload_catalog(catalog_xml, user = nil, reason = nil, comment = nil, options = {})
        KillBillClient::Model::Catalog.upload_tenant_catalog(catalog_xml, user, reason, comment, options)
      end

      def upload_overdue_config(overdue_config_xml, user = nil, reason = nil, comment = nil, options = {})
        KillBillClient::Model::Overdue.upload_tenant_overdue_config_xml(overdue_config_xml, user, reason, comment, options)
      end

      def upload_invoice_template(invoice_template, is_manual_pay, delete_if_exists, user = nil, reason = nil, comment = nil, options = {})
        KillBillClient::Model::Invoice.upload_invoice_template(invoice_template, is_manual_pay, delete_if_exists, user, reason, comment, options)
      end

      def upload_invoice_translation(invoice_translation, locale, delete_if_exists, user = nil, reason = nil, comment = nil, options = {})
        KillBillClient::Model::Invoice.upload_invoice_translation(invoice_translation, locale, delete_if_exists, user, reason, comment, options)
      end

      def upload_catalog_translation(catalog_translation, locale, delete_if_exists, user = nil, reason = nil, comment = nil, options = {})
        KillBillClient::Model::Invoice.upload_catalog_translation(catalog_translation, locale, delete_if_exists, user, reason, comment, options)
      end

      def upload_tenant_plugin_config(plugin_name, plugin_config, user = nil, reason = nil, comment = nil, options = {})
        KillBillClient::Model::Tenant.upload_tenant_plugin_config(plugin_name, plugin_config, user, reason, comment, options)
      end

      # Return a map of plugin_name => config
      def get_tenant_plugin_config(options)
        raw_tenant_config = KillBillClient::Model::Tenant.search_tenant_config('PLUGIN_CONFIG_', options)

        raw_tenant_config.each_with_object({}) do |e, hsh|
          # Strip prefix '/PLUGIN_CONFIG_'
          plugin_name = e.key.gsub!(/PLUGIN_CONFIG_/, '')

          # Construct simple hash with one property (first value)
          hsh[plugin_name] = e.values[0]
        end
      end

      def format_plugin_config(plugin_key, plugin_type, props)
        return nil unless props.present?
        return props['raw_config'].gsub(/\r\n?/, "\n") if props['raw_config']

        if plugin_type == 'ruby'
          require 'yaml'
          props = reformat_plugin_config(plugin_type, props)
          hsh = {}
          hsh[plugin_key.to_sym] = {}
          props.each do |k, v|
            hsh[plugin_key.to_sym][k.to_sym] = v
          end
          hsh.to_yaml
        elsif plugin_type == 'java'
          props = reformat_plugin_config(plugin_type, props)
          res = ''
          props.each do |k, v|
            res = "#{res}#{k}=#{v}\n"
          end
          res
        else
          props['raw_config']
        end
      end

      def reformat_plugin_config(_plugin_type, props)
        unless props['raw_config'].blank?
          new_props = {}
          props['raw_config'].split("\n").each do |p|
            line = p.split('=')
            new_props[line[0]] = line[1].blank? ? '' : line[1].delete("\r")
          end

          return new_props
        end

        props
      end

      # checks if string could be parse as yaml
      def yaml?(candidate_string)
        is_yaml = false
        return is_yaml if candidate_string.blank?

        begin
          is_yaml = !YAML.load(candidate_string).nil?
          is_yaml &&= YAML.load(candidate_string).instance_of?(Hash)
        rescue StandardError
          is_yaml = false
        end

        is_yaml
      end

      # checks if string could be parse as key value pair
      def kv?(candidate_string)
        return false if candidate_string.blank? || yaml?(candidate_string)

        lines = candidate_string.split("\n")
        return false if lines.blank?

        lines.all? { |kv| kv.split('=').count >= 1 }
      end
    end
  end
end
