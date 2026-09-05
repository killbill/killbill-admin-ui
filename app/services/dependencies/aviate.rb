# frozen_string_literal: true

module Dependencies
  module Aviate
    # Thin wrapper around the Aviate plugin's Catalog and Metering REST APIs
    # (https://apidocs.killbill.io/aviate-catalog.html, https://apidocs.killbill.io/aviate-metering.html).
    # These are not (yet) exposed by the killbill-client gem, so we call them directly.
    #
    # Unlike most Kill Bill APIs, these endpoints do NOT accept tenant RBAC (username/password) or
    # api_key/api_secret alone - they require a JWT obtained via the Aviate Auth API
    # (https://apidocs.killbill.io/aviate-auth.html), passed as a `jwt_token` entry in options_for_klient
    # (see Aviate::EngineController#options_for_klient in killbill-aviate-ui, which stores it in a
    # `jwt_token` cookie after logging in via the Aviate Configuration page). If no jwt_token is present,
    # calls will fail authentication and callers should treat that as "unknown/not Aviate".
    class Metering
      KILLBILL_AVIATE_PREFIX = '/plugins/aviate-plugin/v1'
      CATALOG_STATE_AVIATE = 'CATALOG_STATE_AVIATE'

      class << self
        # Returns true if the tenant/account is using an Aviate catalog (as opposed to an XML one).
        # Any error (plugin not installed, missing/invalid JWT, network issue, etc.) is treated as
        # "not Aviate" so that callers can safely fall back to the existing XML-catalog behavior.
        def aviate_catalog?(account_id, options_for_klient)
          params_list = account_id.present? ? [{ accountId: account_id }, {}] : [{}]
          params_list.each do |params|
            response = KillBillClient::API.get("#{KILLBILL_AVIATE_PREFIX}/catalog/info", params, request_options(options_for_klient))
            return true if JSON.parse(response.body)['state'] == CATALOG_STATE_AVIATE
          rescue StandardError => e
            Rails.logger.warn("Failed to retrieve Aviate catalog info (params=#{params}): #{e.class}: #{e.message}")
          end
          false
        end

        # Returns the list of billing meter codes configured on the given plan's usage phases.
        def billing_meter_codes_for_plan(plan_name, account_id, options_for_klient)
          return [] if plan_name.blank?

          response = KillBillClient::API.get("#{KILLBILL_AVIATE_PREFIX}/catalog/#{plan_name}/plan", catalog_params(account_id), request_options(options_for_klient))
          plan = JSON.parse(response.body)

          codes = []
          Array(plan['phases']).each do |phase|
            Array(phase['usages']).each do |usage|
              Array(usage['tiers']).each do |tier|
                Array(tier['blocks']).each do |block|
                  codes << block['billingMeterCode'] if block['billingMeterCode'].present?
                end
              end
            end
          end
          codes.uniq
        rescue StandardError => e
          Rails.logger.warn("Failed to retrieve Aviate billing meter codes for plan #{plan_name}: #{e.class}: #{e.message}")
          []
        end

        # Submits a single usage event via the Aviate metering plugin.
        def submit_usage_event(account_id, billing_meter_code, subscription_id, tracking_id, timestamp, value, options_for_klient)
          body = [{
            billingMeterCode: billing_meter_code,
            subscriptionId: subscription_id,
            trackingId: tracking_id,
            timestamp: timestamp,
            value: value
          }].to_json

          KillBillClient::API.post("#{KILLBILL_AVIATE_PREFIX}/metering/billing/#{account_id}", body, {}, request_options(options_for_klient))
        end

        private

        def catalog_params(account_id)
          account_id.present? ? { accountId: account_id } : {}
        end

        # Builds request options scoped to just api_key/api_secret + the Aviate JWT bearer header.
        # Deliberately excludes username/password/session_id from options_for_klient: KillBillClient's
        # net_http_adapter calls request.basic_auth(username, password) when they're present, which
        # would overwrite (clobber) the Authorization header we set below for the Bearer token.
        def request_options(options_for_klient)
          request_options = {
            api_key: options_for_klient[:api_key],
            api_secret: options_for_klient[:api_secret]
          }
          jwt_token = options_for_klient[:jwt_token]
          request_options[:head] = { 'Authorization' => "Bearer #{jwt_token}" } if jwt_token.present?
          request_options
        end
      end
    end
  end
end
