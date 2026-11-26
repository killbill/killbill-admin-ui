# frozen_string_literal: true

module Kaui
  module SsoCognito
    # Common part of the endpoints called by a web application whose users signed in with AWS Cognito
    # (see Kaui::SsoCognitoController and Kaui::SsoCognito::TenantsController).
    #
    # Not an ApplicationController: the host application's one may require a signed-in user.
    # The endpoints are disabled (404) unless the Cognito issuer and client ids are configured
    # (see Kaui::CognitoJwtVerifier and #ensure_cognito_configured).
    class BaseController < ActionController::Base # rubocop:disable Rails/ApplicationController
      include Kaui::KbCognitoAuthenticatable

      # The calls are cross-site API calls authenticated by the Cognito token. The CSRF protection stays on for any
      # request without a bearer token: a cross-site form cannot set the Authorization header.
      protect_from_forgery with: :exception, unless: -> { request.headers['Authorization'].to_s.start_with?('Bearer ') }

      # Declared from the most generic to the most specific (the last matching handler wins)
      rescue_from StandardError do |e|
        Rails.logger.error("#{sso_operation} failed: #{e.class} - #{e.message}")
        Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
        render_error("#{sso_operation} failed", :internal_server_error)
      end
      rescue_from ActionController::InvalidAuthenticityToken do |e|
        Rails.logger.warn("#{sso_operation} rejected: #{e.message}")
        render_error('Missing or invalid Authorization header', :unauthorized)
      end
      rescue_from JWT::DecodeError do |e|
        Rails.logger.error("SSO JWT verification failed: #{e.message}")
        render_error('Invalid or expired token', :unauthorized)
      end
      rescue_from Kaui::KbCognitoAuthenticatable::Error do |e|
        Rails.logger.warn("#{sso_operation} rejected: #{e.message}")
        render_error(e.message, e.status)
      end

      private

      # Name of the operation for the logs and the error messages
      def sso_operation
        'SSO exchange'
      end

      def ensure_cognito_configured
        return if Kaui::CognitoJwtVerifier.configured?

        render_error("Cognito token #{sso_feature} is not enabled on this Kaui (kaui.cognito.issuer / kaui.cognito.client_ids)", :not_found)
      end

      def sso_feature
        'exchange'
      end

      def render_error(message, status)
        render json: { error: message }, status:
      end
    end
  end
end
