module Kaui
  module AccountHelper

    def pretty_account_identifier
      return nil if @account.nil?
      @account.name.presence || @account.email.presence || truncate_uuid(@account.external_key)
    end

    def email_notifications_plugin_available?
      Kenui::EmailNotificationService.email_notification_plugin_available?(Kaui.current_tenant_user_options(current_user, session)).first
    rescue
      return false
    end

    def account_closed?
      return false if @account.nil?
      blocking_states = @account.blocking_states('ACCOUNT','account-service','NONE', Kaui.current_tenant_user_options(current_user, session))

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
      unless can?(:trigger, Kaui::Payment) && can?(:credit, Kaui::Account) && can?(:charge, Kaui::Account)
        style = "#{style}margin-top:15px;"
      end

      unless can? :trigger, Kaui::Invoice
        style = "#{style}margin-bottom:15px;"
      end

      style = "style='#{style}'" unless style.empty?
      style
    end

  end
end
