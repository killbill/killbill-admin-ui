# frozen_string_literal: true

module Kaui
  class AccountEmail < KillBillClient::Model::AccountEmailAttributes
    def self.find_all_sorted_by_account_id(account_id, audit = 'NONE', options = {})
      emails = Kaui::Account.new(account_id:).emails(audit, options)
      emails.map { |email| Kaui::AccountEmail.new(email.to_hash) }.sort
    end

    def create(user = nil, reason = nil, comment = nil, options = {})
      account = Kaui::Account.new(account_id:)
      account.add_email(email, user, reason, comment, options)
    end

    def destroy(user = nil, reason = nil, comment = nil, options = {})
      account = Kaui::Account.new(account_id:)
      account.remove_email(email, user, reason, comment, options)
    end

    def <=>(other)
      if other.nil?
        -1
      elsif other.email.nil?
        email.nil? ? 0 : 1
      else
        email.to_s <=> other.email.to_s
      end
    end
  end
end
