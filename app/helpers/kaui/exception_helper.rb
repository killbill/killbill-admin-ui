# frozen_string_literal: true

module Kaui
  module ExceptionHelper
    def standardize_exception(exception)
      if defined?(JRUBY_VERSION)
        case exception
        when ActiveRecord::JDBCError, ActiveRecord::NoDatabaseError, ActiveRecord::DatabaseConnectionError, ActiveRecord::ConnectionNotEstablished
          return I18n.t('errors.messages.unable_to_connect_database')
        else
          return exception.message
        end
      end

      case exception
      when ActiveRecord::DatabaseConnectionError
        I18n.t('errors.messages.unable_to_connect_database')
      when Errno::ECONNREFUSED, Errno::EBADF
        I18n.t('errors.messages.unable_to_connect_killbill')
      when ->(e) { e.class.name.start_with?('KillBillClient::API') }
        I18n.t('errors.messages.error_communicating_killbill')
      else
        # Show detailed error in development/test, or when KAUI_SHOW_ERROR_DETAILS is set (for Docker)
        show_details = Rails.env.development? || Rails.env.test? || ENV['KAUI_SHOW_ERROR_DETAILS'].present?
        show_details ? exception.message : nil
      end
    end
  end
end
