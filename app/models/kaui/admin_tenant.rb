class Kaui::AdminTenant < KillBillClient::Model::Tenant


  class << self
    def upload_catalog(catalog_xml, user = nil, reason = nil, comment = nil, options = {})
      KillBillClient::Model::Catalog.upload_tenant_catalog(catalog_xml, user, reason, comment, options)
    end
  end

  def create(admin_user = nil, reason = nil, comment = nil, options = {})
    created = super(admin_user, reason, comment, options)

    # Return a KAUI model that we will also store
    new_tenant = Kaui::Tenant.new
    new_tenant.name = created.external_key
    new_tenant.kb_tenant_id = created.tenant_id
    new_tenant.api_key = created.api_key
    new_tenant.api_secret = api_secret
    new_tenant
  end

end