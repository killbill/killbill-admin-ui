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

    def get_oss_plugin_info

      require 'open-uri'
      require 'yaml'

      source = URI.parse('https://raw.githubusercontent.com/killbill/killbill-cloud/master/kpm/lib/kpm/plugins_directory.yml').read
      plugin_directory = YAML.load(source)

      # Serialize the plugin state for the view:
      #  plugin_name#plugin_type:prop1,prop2,prop3;plugin_name#plugin_type:prop1,prop2,prop3;...
      #
      plugin_config = plugin_directory.inject({}) do |hsh, (k,v)|
        hsh["#{k}##{v[:type]}"] = v[:require] || []
        hsh
      end
      plugin_config.map { |e,v| "#{e}:#{v.join(",")}" }.join(";")
    end

    def format_plugin_config(plugin_name, plugin_type, props)
      if plugin_type == 'ruby'
        require 'yaml'
        hsh = {}
        hsh[plugin_name.to_sym] = {}
        props.each do |k,v|
          hsh[plugin_name.to_sym][k.to_sym] = v.to_sym
        end
        hsh[plugin_name.to_sym]
        hsh.to_yaml
      else # java
        res = ""
        props.each do |k,v|
          res = "#{res}#{k.to_s}=#{v.to_s}\n"
        end
        res
      end

    end
  end
end