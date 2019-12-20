class Kaui::AdminTenant < KillBillClient::Model::Tenant


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

    def get_plugin_repository
      require 'open-uri'
      require 'yaml'

      source = URI.parse('https://raw.githubusercontent.com/killbill/killbill-cloud/master/kpm/lib/kpm/plugins_directory.yml').read
      YAML.load(source)
    rescue
      # Ignore gracefully
      {}
    end

    def get_oss_plugin_info(plugin_directory)
      # Serialize the plugin state for the view:
      #  plugin_name#plugin_type:prop1,prop2,prop3;plugin_name#plugin_type:prop1,prop2,prop3;...
      #
      plugin_config = plugin_directory.inject({}) do |hsh, (k,v)|
        hsh["#{k}##{v[:type]}"] = v[:require] || []
        hsh
      end
      plugin_config.map { |e,v| "#{e}:#{v.join(",")}" }.join(";")
    end

    # Return a map of plugin_name => config
    def get_tenant_plugin_config(plugin_directory, options)
      raw_tenant_config = KillBillClient::Model::Tenant::search_tenant_config("PLUGIN_CONFIG_", options)

      tenant_config = raw_tenant_config.inject({}) do |hsh, e|
        # Strip prefix '/PLUGIN_CONFIG_'
        plugin_name = e.key.gsub!(/PLUGIN_CONFIG_/, '')

        # Construct simple hash with one property (first value)
        hsh[plugin_name] = e.values[0]

        hsh
      end

      tenant_config
    end

    def format_plugin_config(plugin_key, plugin_type, props)
      return nil unless props.present?
      return props['raw_config'].gsub(/\r\n?/, "\n") if props['raw_config']

      if plugin_type == 'ruby'
        require 'yaml'
        props = reformat_plugin_config(plugin_type, props)
        hsh = {}
        hsh[plugin_key.to_sym] = {}
        props.each do |k,v|
          hsh[plugin_key.to_sym][k.to_sym] = v
        end
        hsh.to_yaml
      elsif plugin_type == 'java'
        props = reformat_plugin_config(plugin_type, props)
        res = ""
        props.each do |k, v|
          res = "#{res}#{k.to_s}=#{v.to_s}\n"
        end
        res
      else
        props['raw_config']
      end
    end

    def reformat_plugin_config(plugin_type, props)
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
    def is_yaml?(candidate_string)
      is_yaml = false
      return is_yaml if candidate_string.blank?

      begin
        is_yaml = !!YAML::load(candidate_string)
        is_yaml = is_yaml && YAML.load(candidate_string).instance_of?(Hash)
      rescue
        is_yaml = false
      end

      is_yaml
    end

    # checks if string could be parse as key value pair
    def is_kv?(candidate_string)
      return false if candidate_string.blank? || is_yaml?(candidate_string)
      lines = candidate_string.split("\n")
      return false if lines.blank?

      lines.all? { |kv| kv.split('=').count >= 1 }
    end
  end
end
