# frozen_string_literal: true

module Kaui
  # Shared Cognito token + Kill Bill authentication flow of the Cognito token exchange (see Kaui::SsoCognitoController).
  # It can be included by other controllers (e.g. custom ones living in a Kaui deployment) to get the same login.
  #
  # Two modes, selected by the client:
  #
  # * basic:  Cognito ID token + kb_username/kb_password. Kaui logs into Kill Bill with Basic auth. The Kaui user is
  #           kb_username (defaults to the email of the token), the tenant comes from kaui_allowed_users.
  # * bearer: Cognito ID token, no kb_password (the Kill Bill instance needs the Cognito realm). Kaui logs into Kill Bill
  #           with the Bearer token. The Kaui user is the principal reported by Kill Bill (e.g. cognito:alice@acme.com)
  #           and the tenant comes from the tenant api key/secret (tenant_api_key and tenant_api_secret).
  module KbCognitoAuthenticatable
    # An error to report to the client with the given HTTP status
    class Error < StandardError
      attr_reader :status

      def initialize(message, status)
        super(message)
        @status = status
      end
    end

    # Name of the session key flagging a session established by the exchange. It is used by killbill-aviate
    # (Aviate::SSO_SESSION_KEY) to display the Aviate sidebar, hence only set here, after reset_session.
    SSO_SESSION_KEY = :aviate_sso

    private

    def warden
      request.env['warden']
    end

    def extract_bearer_token
      auth_header = request.headers['Authorization'].to_s
      token = auth_header.start_with?('Bearer ') ? auth_header.split(' ', 2)[1].to_s.strip : nil
      raise Error.new('Missing or invalid Authorization header', :unauthorized) if token.blank?

      token
    end

    # Basic mode when the client sends the Kill Bill password, bearer mode otherwise
    def kb_bearer_mode?
      params[:kb_password].blank?
    end

    # Returns the authenticated Kaui::User, and signs it in
    def authenticate_kb_user!
      token = extract_bearer_token
      claims = Kaui::CognitoJwtVerifier.verify!(token)

      if kb_bearer_mode?
        # Check the tenant before logging in, so that a wrong key/secret doesn't leave a session around
        @kb_exchange_tenant = find_tenant_from_api_credentials!
        user, kb_session_id = login_to_kb_with_bearer!(token)
      else
        user, kb_session_id = login_to_kb_with_password!(claims)
      end

      user.kb_session_id = kb_session_id
      user.save!

      reset_session
      warden.set_user(user, scope: :user, store: true)
      # Flag the session as signed in through the exchange: killbill-aviate (Aviate::SSO_SESSION_KEY) then displays the
      # Aviate sidebar on the Kaui pages. Set after reset_session, so it only lives as long as this session.
      session[SSO_SESSION_KEY] = true

      user
    end

    # Verifies the Cognito token and logs into Kill Bill (basic or bearer mode), like authenticate_kb_user!, but for the API
    # calls that must not change the session of the browser, and that do not need a tenant yet (e.g. to register one).
    # Returns the Kaui::User (saved, with the Kill Bill session id). No Warden session, no tenant check.
    def authenticate_kb_user_without_session!
      token = extract_bearer_token
      claims = Kaui::CognitoJwtVerifier.verify!(token)

      user, kb_session_id = kb_bearer_mode? ? login_to_kb_with_bearer!(token) : login_to_kb_with_password!(claims)
      user.kb_session_id = kb_session_id
      user.save!
      user
    end

    def login_to_kb_with_password!(claims)
      kb_username = params[:kb_username].presence || claims['email'].to_s.downcase.presence
      raise Error.new('kb_username is required when the token has no email claim', :bad_request) if kb_username.blank?

      response = Kaui::User.find_permissions(username: kb_username, password: params[:kb_password])
      [Kaui::User.find_or_initialize_by(kb_username:), response.session_id]
    rescue KillBillClient::API::Unauthorized
      raise Error.new('Invalid Kill Bill credentials', :unauthorized)
    end

    def login_to_kb_with_bearer!(token)
      response = Kaui::User.find_permissions(bearer: token)
      # Key the Kaui user by the principal Kill Bill reports (e.g. cognito:alice@acme.com), not by the bare email:
      # a bearer user never shares the Kaui row, Kill Bill session and tenants of a basic user with the same name
      principal = KillBillClient::Model::Security.find_subject(session_id: response.session_id).principal
      raise Error.new('Kill Bill did not report a principal for this token', :unauthorized) if principal.blank?

      [Kaui::User.find_or_initialize_by(kb_username: principal), response.session_id]
    rescue KillBillClient::API::Unauthorized
      raise Error.new('Cognito authentication is not enabled on this Kill Bill, or the token is not accepted by its Cognito realm', :unauthorized)
    end

    # Bearer mode: returns the tenant identified by the api key/secret of the request (nil if none was sent)
    def find_tenant_from_api_credentials!
      api_key = params[:tenant_api_key].presence
      api_secret = params[:tenant_api_secret].presence
      return nil if api_key.nil? && api_secret.nil?
      raise Error.new('tenant_api_key and tenant_api_secret must be sent together', :bad_request) if api_key.nil? || api_secret.nil?

      tenant = Kaui::Tenant.find_by(api_key:)
      valid = tenant&.api_secret.present? && ActiveSupport::SecurityUtils.secure_compare(tenant.api_secret.to_s, api_secret.to_s)
      raise Error.new('Unknown tenant or invalid tenant api secret', :forbidden) unless valid

      tenant
    end

    # Selects the tenant of the session for the given user when possible.
    #
    # In bearer mode, it is the tenant of the api key/secret (the user is allowed on it).
    #
    # In basic mode (kaui_allowed_users):
    # - a single allowed tenant is always selected
    # - with multiple tenants, the `tenant_name` param is used to disambiguate
    # - otherwise, when default_to_first is true, the first tenant is used
    #   as a default; when false, the user is left for tenant selection
    def select_tenant_for_user(user, log_prefix:, default_to_first: true)
      return select_tenant_from_api_credentials(user, log_prefix:) if kb_bearer_mode?

      allowed_user = Kaui::AllowedUser.find_by(kb_username: user.kb_username)
      return unless allowed_user

      tenants = allowed_user.kaui_tenants

      if tenants.size == 1
        tenant = tenants.first
        set_tenant_session(tenant)
        Rails.logger.info("#{log_prefix}: Auto-selected tenant #{tenant.name} for user #{user.kb_username}")
      elsif tenants.size > 1 && params[:tenant_name].present?
        tenant = tenants.find { |t| t.name == params[:tenant_name] }
        if tenant
          set_tenant_session(tenant)
          Rails.logger.info("#{log_prefix}: Selected tenant #{tenant.name} for user #{user.kb_username}")
        else
          Rails.logger.warn("#{log_prefix}: Tenant '#{params[:tenant_name]}' not found for user #{user.kb_username}")
        end
      elsif tenants.size > 1 && default_to_first
        tenant = tenants.first
        set_tenant_session(tenant)
        Rails.logger.info("#{log_prefix}: Default-selected first tenant #{tenant.name} for user #{user.kb_username}")
      end
    end

    # Selects the tenant validated by find_tenant_from_api_credentials! and makes sure the user is allowed on it
    # (so that the Kaui tenant screen lists it)
    def select_tenant_from_api_credentials(user, log_prefix:)
      tenant = @kb_exchange_tenant
      return unless tenant

      allowed_user = begin
        Kaui::AllowedUser.find_or_create_by!(kb_username: user.kb_username)
      rescue ActiveRecord::RecordNotUnique
        Kaui::AllowedUser.find_by!(kb_username: user.kb_username)
      end

      begin
        Kaui::AllowedUserTenant.find_or_create_by!(kaui_allowed_user: allowed_user, kaui_tenant: tenant)
      rescue ActiveRecord::RecordNotUnique
        nil # Concurrent exchange for the same user
      end

      set_tenant_session(tenant)
      Rails.logger.info("#{log_prefix}: Selected tenant #{tenant.name} for user #{user.kb_username}")
    end

    def set_tenant_session(tenant) # rubocop:disable Naming/AccessorMethodName
      session[:kb_tenant_id] = tenant.kb_tenant_id
      session[:kb_tenant_name] = tenant.name
      session[:tenant_id] = tenant.id
    end
  end
end
