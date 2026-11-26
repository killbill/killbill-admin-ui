# frozen_string_literal: true

module Kaui
  # Optional Cognito token exchange: a web application whose users signed in with AWS Cognito can open Kaui for them
  # without a second login (see Kaui::KbCognitoAuthenticatable and Kaui::CognitoJwtVerifier).
  #
  #   POST /sso/cognito/exchange (alias: POST /sso/aviate/exchange)
  #   Authorization: Bearer <Cognito ID token>
  #   body: kb_username/kb_password (basic mode) or tenant_api_key/tenant_api_secret (bearer mode), optionally
  #         tenant_name (basic mode) and target (path of the Kaui page to open)
  #
  # Disabled (404) unless the Cognito issuer and client ids are configured (see Kaui::CognitoJwtVerifier).
  class SsoCognitoController < Kaui::SsoCognito::BaseController
    ALLOWED_TARGETS = %w[/accounts /invoices /payments /bundles /subscriptions].freeze

    before_action :ensure_cognito_configured, only: :exchange

    def exchange
      # Verify the token, authenticate against Kill Bill, and establish the Warden session of the Kaui::User
      user = authenticate_kb_user!
      Rails.logger.info("SSO: Authenticated #{user.kb_username} (user ##{user.id})")

      # Select the tenant if possible. This prevents the redirect to the tenant selection page
      select_tenant_for_user(user, log_prefix: 'SSO', default_to_first: false)

      render json: { redirectUrl: sso_target_url }, status: :ok
    end

    # Instead of the sign-in form (they have no Kill Bill password), for the users whose Kill Bill session expired:
    # back to the login page of the application they came from if it is configured, an explanation otherwise
    def session_expired
      login_url = Kaui::CognitoJwtVerifier.login_url
      return redirect_to(login_url, allow_other_host: true) if login_url

      render layout: false
    end

    private

    def sso_target_url
      # Allow only known internal paths to avoid open redirect vulnerability
      path = params[:target].to_s.strip
      path = '/' if path.blank? || path.include?('..') || path.include?('\\')

      # Only allow the home page or the known pages (and their sub-paths), home otherwise
      path = '/' unless path == '/' || ALLOWED_TARGETS.any? { |allowed| path == allowed || path.start_with?("#{allowed}/") }

      # The full URL includes the context path Kaui is mounted at (e.g. /kaui)
      "#{request.protocol}#{request.host_with_port}#{request.script_name}#{path}"
    end
  end
end
