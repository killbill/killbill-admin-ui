# frozen_string_literal: true

module Kaui
  module ExceptionHelper
    def standardize_exception(exception)
      if defined?(JRUBY_VERSION)
        case exception
        when ActiveRecord::JDBCError, ActiveRecord::NoDatabaseError, ActiveRecord::DatabaseConnectionError, ActiveRecord::ConnectionNotEstablished
          return I18n.translate('errors.messages.unable_to_connect_database')
        else
          return "#{exception.message}"
        end
      end

      case exception
      when ActiveRecord::DatabaseConnectionError
        I18n.translate('errors.messages.unable_to_connect_database')
      when Errno::ECONNREFUSED, Errno::EBADF
        I18n.translate('errors.messages.unable_to_connect_killbill')
      when ->(e) { e.class.name.start_with?('KillBillClient::API') }
        I18n.translate('errors.messages.error_communicating_killbill')
      else
        nil
      end
    end
  end
end
