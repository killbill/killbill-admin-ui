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
  end
end