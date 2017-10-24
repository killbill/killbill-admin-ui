module Kaui
  module AccountHelper

    def pretty_account_identifier
      return nil if @account.nil?
      @account.name.presence || @account.email.presence || truncate_uuid(@account.external_key)
    end

    def email_notifications_plugin_available?
      Kenui::EmailNotificationService.email_notification_plugin_available?(Kaui.current_tenant_user_options(current_user, session)).first
    end
  end
end
