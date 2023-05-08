# frozen_string_literal: true

module Kaui
  module AccountHelper
    def pretty_account_identifier
      return nil if @account.nil?

      Kaui.pretty_account_identifier.call(@account)
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

    def account_closed?
      return false if @account.nil?

      # NOTE: we ignore errors here, so that the call doesn't prevent the screen to load. While the error isn't surfaced, if there is an error with the catalog for instance,
      # the AJAX call to compute the next invoice date should hopefully trigger a flash error.
      blocking_states = begin
        @account.blocking_states('ACCOUNT', 'account-service', 'NONE', Kaui.current_tenant_user_options(current_user, session))
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
  end
end
