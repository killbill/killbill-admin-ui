# frozen_string_literal: true

module Kaui
  module AccountHelper
    def pretty_account_identifier(account = nil)
      account ||= @account # rubocop:disable Rails/HelperInstanceVariable
      return nil if account.nil?

      Kaui.pretty_account_identifier.call(account)
    end

    def email_notifications_plugin_available?
      Kenui::EmailNotificationService.email_notification_plugin_available?(Kaui.current_tenant_user_options(current_user, session)).first
    rescue StandardError
      false
    end

    def deposit_plugin_available?
      Killbill::Deposit::DepositClient.deposit_plugin_available?(Kaui.current_tenant_user_options(current_user, session)).first
    rescue StandardError
      false
    end

    def aviate_plugin_installed
      Killbill::Aviate::AviateClient.aviate_plugin_installed(Kaui.current_tenant_user_options(current_user, session)).first
    rescue StandardError
      false
    end

    def kpm_plugin_installed
      nodes_info = KillBillClient::Model::NodesInfo.nodes_info(Kaui.current_tenant_user_options(current_user, session)) || []
      return false if nodes_info.empty?

      nodes_info.each do |node_info|
        next if (node_info.plugins_info || []).empty?

        node_info.plugins_info.each do |plugin_info|
          return true if plugin_info.plugin_name == 'org.kill-bill.billing.killbill-platform-osgi-bundles-kpm'
        end
      end
    end

    def account_closed?(account = nil)
      account ||= @account # rubocop:disable Rails/HelperInstanceVariable
      return false if account.nil?

      # NOTE: we ignore errors here, so that the call doesn't prevent the screen to load. While the error isn't surfaced, if there is an error with the catalog for instance,
      # the AJAX call to compute the next invoice date should hopefully trigger a flash error.
      blocking_states = begin
        account.blocking_states('ACCOUNT', 'account-service', 'NONE', Kaui.current_tenant_user_options(current_user, session))
      rescue StandardError
        []
      end

      is_account_closed = false
      blocking_states.each do |blocking_state|
        if blocking_state.state_name.eql?('CLOSE_ACCOUNT')
          is_account_closed = true
          break
        end
      end
      is_account_closed
    end

    def billing_info_margin
      style = ''
      style = "#{style}margin-top:15px;" unless can?(:trigger, Kaui::Payment) && can?(:credit, Kaui::Account) && can?(:charge, Kaui::Account)

      style = "#{style}margin-bottom:15px;" unless can? :trigger, Kaui::Invoice

      style = "style='#{style}'" unless style.empty?
      style
    end

    # Get the effective BCD for an account
    # If there's an active subscription with its own BCD, return that
    # Otherwise return the account-level BCD
    def effective_bcd(account, bundles = nil)
      # If bundles are provided, check for subscription BCD
      if bundles.present?
        bundles.each do |bundle|
          next if bundle.subscriptions.blank?

          bundle.subscriptions.each do |subscription|
            # Skip cancelled subscriptions
            next if subscription.state == 'CANCELLED'
            # If subscription has a BCD set, return it (subscription BCD takes precedence)
            return subscription.bill_cycle_day_local if subscription.bill_cycle_day_local.present? && subscription.bill_cycle_day_local.positive?
          end
        end
      end

      # Fall back to account BCD
      account.bill_cycle_day_local
    end
  end
end
