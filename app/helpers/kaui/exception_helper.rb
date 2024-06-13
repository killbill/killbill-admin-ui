# frozen_string_literal: true

module Kaui
  module ExceptionHelper
    def standardize_exception(exception)
      case exception
      when ActiveRecord::DatabaseConnectionError, ActiveRecord::JDBCError
        I18n.translate('errors.messages.unable_to_connect_database')
      when Errno::ECONNREFUSED
        url = exception.message.match(/for "(.*)" port/) { |m| m[1] }
        url && (KillBillClient.url.include? url) ? I18n.translate('errors.messages.unable_to_connect_killbill') : nil
      when ->(e) { e.class.name.start_with?('KillBillClient::API') }
        I18n.translate('errors.messages.error_communicating_killbill')
      else
        nil
      end
    end
  end
end
