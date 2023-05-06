# frozen_string_literal: true

module Kaui
  class Bundle < KillBillClient::Model::Bundle
    def self.find_by_id_or_key(bundle_id_or_key, options = {})
      if bundle_id_or_key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
        bundle = begin
          find_by_id(bundle_id_or_key, options)
        rescue StandardError
          nil
        end
        return bundle unless bundle.nil?
      end

      # Return the active one
      find_by_external_key(bundle_id_or_key, false, options)
    end

    def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
      if search_key.present?
        find_in_batches_by_search_key(search_key, offset, limit, options)
      else
        find_in_batches(offset, limit, options)
      end
    end

    def self.get_active_bundle_or_latest_created(bundles, time_zone = nil)
      return nil if bundles.empty?

      latest_start_date = nil
      latest_bundle     = nil

      bundles.each do |b|
        b.subscriptions.each do |s|
          next unless s.product_category != 'ADD_ON'

          if latest_start_date.nil? || latest_start_date < s.start_date
            latest_start_date = s.start_date
            latest_bundle     = b
          end

          return b if s.cancelled_date.nil? || s.cancelled_date > ActionController::Base.helpers.current_time(time_zone)
        end
      end

      latest_bundle
    end

    def self.list_transfer_policy_params
      @policy_params = [
        [I18n.translate('start_of_term'), 'START_OF_TERM'],
        [I18n.translate('end_of_term'), 'END_OF_TERM'],
        [I18n.translate('immediate'), 'IMMEDIATE']
      ]
    end

    def self.list_transfer_policy_params_keys
      @policy_params = %w[START_OF_TERM END_OF_TERM IMMEDIATE]
    end
  end
end
