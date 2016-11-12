module Kaui
  module AccountHelper

    def pretty_account_identifier
      return nil if @account.nil?
      @account.name.presence || @account.email.presence || @account.external_key
    end
  end
end
