# frozen_string_literal: true

module Kaui
  module SsoCognito
    # Registers in Kaui a tenant that was created in Kill Bill by the web application (e.g. Aviate), and grants the user
    # access to it.
    #
    #   POST /sso/cognito/tenants (alias: POST /sso/aviate/tenants)
    #   Authorization: Bearer <Cognito ID token>
    #   body: kb_username/kb_password (basic mode, none in bearer mode), name, tenantKey, tenantSecret, kbTenantId
    #
    #   201 the tenant was registered, 200 it already was (the user is granted access to it),
    #   400 missing parameter, 401 invalid token or Kill Bill credentials, 403 tenantKey/tenantSecret rejected by Kill Bill
    #   or not the tenant kbTenantId, 409 the name is already used by another tenant, 404 Cognito not configured.
    #
    # Unlike the exchange, it does not create a session for the browser: the user keeps the session they have (if any).
    # Disabled (404) unless the Cognito issuer and client ids are configured (see Kaui::CognitoJwtVerifier).
    class TenantsController < BaseController
      REQUIRED_PARAMS = %i[name tenantKey tenantSecret kbTenantId].freeze

      before_action :ensure_cognito_configured

      def create
        user = authenticate_kb_user_without_session!

        missing = REQUIRED_PARAMS.select { |p| params[p].blank? }
        raise Kaui::KbCognitoAuthenticatable::Error.new("Missing required parameter(s): #{missing.join(', ')}", :bad_request) unless missing.empty?

        verify_tenant_credentials!(user)
        tenant, created = register_tenant(user)
        Rails.logger.info("Tenant registration: #{user.kb_username} #{created ? 'registered' : 'was granted access to'} tenant #{tenant.name}")

        render json: { id: tenant.id, name: tenant.name, kbTenantId: tenant.kb_tenant_id, tenantKey: tenant.api_key }, status: created ? :created : :ok
      end

      private

      def sso_operation
        'Tenant registration'
      end

      def sso_feature
        'registration'
      end

      # The tenant must exist in Kill Bill, with these credentials and this id: anyone with a valid Cognito token could
      # otherwise register (and squat the name of) any tenant
      def verify_tenant_credentials!(user)
        options = { username: user.kb_username, session_id: user.kb_session_id, api_key: params[:tenantKey], api_secret: params[:tenantSecret] }
        kb_tenant = Kaui::AdminTenant.find_by_api_key(params[:tenantKey], options)
        return if kb_tenant.tenant_id.to_s == params[:kbTenantId].to_s

        raise Kaui::KbCognitoAuthenticatable::Error.new('tenantKey is not the Kill Bill tenant kbTenantId', :forbidden)
      rescue KillBillClient::API::Unauthorized, KillBillClient::API::Forbidden, KillBillClient::API::NotFound, KillBillClient::API::Conflict
        raise rejected_credentials
      rescue KillBillClient::API::InternalServerError => e
        # Kill Bill answers with a 500 for an unknown api key
        raise e unless e.message&.include?('TenantCacheLoader cannot find value')

        raise rejected_credentials
      end

      def rejected_credentials
        Kaui::KbCognitoAuthenticatable::Error.new('Kill Bill rejected the tenant credentials (tenantKey/tenantSecret)', :forbidden)
      end

      # Returns the Kaui tenant and whether it was created (false: it was already registered, with the same Kill Bill tenant)
      def register_tenant(user)
        tenant = Kaui::Tenant.find_by(kb_tenant_id: params[:kbTenantId]) || Kaui::Tenant.find_by(api_key: params[:tenantKey])
        by_name = Kaui::Tenant.find_by(name: params[:name])
        raise Kaui::KbCognitoAuthenticatable::Error.new('A tenant with this name already exists', :conflict) if by_name && by_name != tenant

        created = tenant.nil?
        tenant ||= Kaui::Tenant.create!(name: params[:name], api_key: params[:tenantKey], api_secret: params[:tenantSecret], kb_tenant_id: params[:kbTenantId])

        allowed_user = Kaui::AllowedUser.where(kb_username: user.kb_username).first_or_create!
        tenant.kaui_allowed_users << allowed_user unless tenant.kaui_allowed_users.include?(allowed_user)
        [tenant, created]
      end
    end
  end
end
