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

    def get_tenant_plugin_config(plugin_directory, options)
      require 'yaml'

      raw_tenant_config = KillBillClient::Model::Tenant::search_tenant_config("PLUGIN_CONFIG_", options)

      tenant_config = raw_tenant_config.inject({}) do |hsh, e|
        # Strip prefix '/PLUGIN_CONFIG_'
        killbill_key = e.key.gsub!(/PLUGIN_CONFIG_/, '')

        # Extract killbill key for oss plugins based on convention 'killbill-KEY'
        plugin_key = killbill_key.gsub(/killbill-/, '') if killbill_key.start_with?('killbill-')

        # hack:: rewrite key, to allow the ui to find the right configuration inputs
        plugin_key = rewrite_plugin_key(plugin_key) unless plugin_key.nil?
        # If such key exists, lookup in plugin directory to see if is an official plugin
        is_an_official_plugin = !plugin_key.nil? && !plugin_directory[plugin_key.to_sym].blank?
        # Deserialize config based on string possible format, if exist in the official repository
        if is_an_official_plugin && is_yaml?(e.values[0])
          yml = YAML.load(e.values[0])
          # Hash of properties
          # is plugin key part of the yaml?
          if yml[plugin_key.to_sym].blank?
            # if not set it as raw
            hsh[plugin_key] = {:raw_config => e.values[0]}
          else
            hsh[plugin_key] = yml[plugin_key.to_sym]
          end
        elsif is_an_official_plugin && is_kv?(e.values[0])
          # Construct hash of properties based on java properties (k1=v1\nk2=v2\n...)
          hsh[plugin_key] = e.values[0].split("\n").inject({}) do |h, p0|
            k, v = p0.split('=');
            h[k] = v;
            h
          end
        else
          # Construct simple hash with one property :raw_config
          hsh[killbill_key] = {:raw_config => e.values[0]}
        end
        hsh
      end

      # Serialize the whole thing a as string of the form:
      # plugin_key1::key1=value1|key2=value2|..;plugin_key2::...
      tenant_config.map do |plugin_key, props|
        serialized_props = props.inject("") do |s, (k, v)|
          e="#{k.to_s}=#{v.to_s}";
          s == "" ? s="#{e}" : s="#{s}|#{e}";
          s
        end
        "#{plugin_key}::#{serialized_props}"
      end.join(";")

    end


    def format_plugin_config(plugin_key, plugin_type, props)
      return nil unless props.present?
      if plugin_type == 'ruby'
        require 'yaml'
        props = reformat_plugin_config(plugin_type, props)
        hsh = {}
        hsh[plugin_key.to_sym] = {}
        props.each do |k,v|
          hsh[plugin_key.to_sym][k.to_sym] = v.to_sym
        end
        hsh[plugin_key.to_sym]
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

    # hack when the plugin name after killbill is not the same as the plugin key, this mainly affects ruby plugin configuration,
    # as it use the key to retrieve the configuration.
    def rewrite_plugin_key(plugin_key)
      if plugin_key.start_with?('paypal')
        'paypal_express'
      elsif plugin_key.start_with?('firstdata')
        'firstdata_e4'
      elsif plugin_key.start_with?('bridge')
        'payment_bridge'
      elsif plugin_key.start_with?('payu-latam')
        'payu_latam'
      else
        "#{plugin_key}"
      end
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
