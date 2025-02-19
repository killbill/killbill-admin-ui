# frozen_string_literal: true

module Dependencies
  module Kenui
    class EmailNotification
      ERROR_MESSAGE = I18n.translate('errors.messages.email_notification_plugin_not_available')
      class << self
        def email_notification_plugin_available?(options_for_klient)
          is_available = ::Kenui::EmailNotificationService.email_notification_plugin_available?(options_for_klient)
          [is_available, is_available ? nil : ERROR_MESSAGE]
        rescue StandardError
          [false, ERROR_MESSAGE]
        end

        def set_configuration_per_account(account_id, event_types, kb_username, reason, comment, options_for_klient)
          ::Kenui::EmailNotificationService.set_configuration_per_account(account_id,
                                                                          event_types,
                                                                          kb_username,
                                                                          reason,
                                                                          comment,
                                                                          options_for_klient)
        rescue StandardError
          [false, ERROR_MESSAGE]
        end

        def get_events_to_consider(options_for_klient)
          ::Kenui::EmailNotificationService.get_events_to_consider(options_for_klient)
        rescue StandardError
          {}
        end

        def get_configuration_per_account(account_id, options_for_klient)
          ::Kenui::EmailNotificationService.get_configuration_per_account(account_id, options_for_klient)
        rescue StandardError
          []
        end
      end
    end
  end
end
