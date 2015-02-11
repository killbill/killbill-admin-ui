class Kaui::AdminTenant < KillBillClient::Model::Tenant


  class << self
    def upload_catalog(catalog_xml, user = nil, reason = nil, comment = nil, options = {})
      KillBillClient::Model::Catalog.upload_tenant_catalog(catalog_xml, user, reason, comment, options)
    end
  end

  def create(admin_user = nil, reason = nil, comment = nil, options = {})
    super(admin_user, reason, comment, options)
  end

end