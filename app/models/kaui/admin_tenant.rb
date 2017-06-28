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
        # If such key exists, lookup in plugin directory
        plugin_repo_entry = plugin_directory[plugin_key.to_sym] unless plugin_key.nil?
        # Extract plugin_type based on plugin_directory entry if exists
        plugin_type = plugin_repo_entry.nil? ? :unknown : plugin_repo_entry[:type].to_sym

        # Deserialize config based on type
        if plugin_type == :ruby
          yml = YAML.load(e.values[0])
          # Hash of properties
          hsh[plugin_key] = yml[plugin_key.to_sym]
        elsif plugin_type == :java
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
      # plugin_key1::key1=value1,key2=value2,..;plugin_key2::...
      tenant_config.map do |plugin_key, props|
        serialized_props = props.inject("") do |s, (k, v)|
          e="#{k.to_s}=#{v.to_s}";
          s == "" ? s="#{e}" : s="#{s},#{e}";
          s
        end
        "#{plugin_key}::#{serialized_props}"
      end.join(";")

    end


    def format_plugin_config(plugin_name, plugin_type, props)
      return nil unless props.present?
      if plugin_type == 'ruby'
        require 'yaml'
        hsh = {}
        hsh[plugin_name.to_sym] = {}
        props.each do |k,v|
          hsh[plugin_name.to_sym][k.to_sym] = v.to_sym
        end
        hsh[plugin_name.to_sym]
        hsh.to_yaml
      elsif plugin_type == 'java'
        res = ""
        props.each do |k, v|
          res = "#{res}#{k.to_s}=#{v.to_s}\n"
        end
        res
      else
        props['raw_config']
      end
    end
  end
end
