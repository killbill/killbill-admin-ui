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
  # Not an ApplicationController: the host application's one may require a signed-in user
  class SsoCognitoController < ActionController::Base # rubocop:disable Rails/ApplicationController
    include Kaui::KbCognitoAuthenticatable

    # The exchange is a cross-site API call authenticated by the Cognito token
    skip_forgery_protection only: [:exchange]

    ALLOWED_TARGETS = %w[/accounts /invoices /payments /bundles].freeze

    # Declared from the most generic to the most specific (the last matching handler wins)
    rescue_from StandardError do |e|
      Rails.logger.error("SSO exchange failed: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      render_error('SSO exchange failed', :internal_server_error)
    end
    rescue_from JWT::DecodeError do |e|
      Rails.logger.error("SSO JWT verification failed: #{e.message}")
      render_error('Invalid or expired token', :unauthorized)
    end
    rescue_from Kaui::KbCognitoAuthenticatable::Error do |e|
      Rails.logger.warn("SSO exchange rejected: #{e.message}")
      render_error(e.message, e.status)
    end

    def exchange
      return render_error('Cognito token exchange is not enabled on this Kaui (kaui.cognito.issuer / kaui.cognito.client_ids)', :not_found) unless Kaui::CognitoJwtVerifier.configured?

      # Verify the token, authenticate against Kill Bill, and establish the Warden session of the Kaui::User
      user = authenticate_kb_user!
      Rails.logger.info("SSO: Authenticated #{user.kb_username} (user ##{user.id})")

      # Select the tenant if possible. This prevents the redirect to the tenant selection page
      select_tenant_for_user(user, log_prefix: 'SSO', default_to_first: false)

      render json: { redirectUrl: sso_target_url }, status: :ok
    end

    # Shown instead of the sign-in form when the Kill Bill session of a user who didn't sign in with a password expired
    def session_expired
      render layout: false
    end

    private

    def render_error(message, status)
      render json: { error: message }, status:
    end

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
