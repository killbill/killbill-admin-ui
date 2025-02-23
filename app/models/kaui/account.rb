# frozen_string_literal: true

module Kaui
  class Account < KillBillClient::Model::Account
    attr_accessor :phone, :bill_cycle_day_local

    SENSIVITE_DATA_FIELDS = %w[name email].freeze
    REMAPPING_FIELDS = {
      'is_payment_delegated_to_parent' => 'pay_via_parent',
      'bill_cycle_day_local' => 'bcd',
      'account_balance' => 'balance',
      'account_cba' => 'cba',
      'is_migrated' => 'migrated'
    }.freeze

    def check_account_details_phone
      return true if phone =~ /\A(?:\+?\d{1,3}\s*-?)?\(?(?:\d{3})?\)?[- ]?\d{3}[- ]?\d{4}\z/i

      false
    end

    def check_account_details_bill_cycle_day_local
      return true if bill_cycle_day_local.to_i.between?(1, 31)

      false
    end

    def self.find_by_id_or_key(account_id_or_key, with_balance, with_balance_and_cba, options = {})
      if account_id_or_key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
        begin
          find_by_id(account_id_or_key, with_balance, with_balance_and_cba, options)
        rescue StandardError => e
          begin
            # account_id_or_key looked like an id, but maybe it's an external key (this will happen in tests)?
            find_by_external_key(account_id_or_key, with_balance, with_balance_and_cba, options)
          rescue StandardError => _
            # Nope - raise the initial exception
            raise e
          end
        end
      else
        find_by_external_key(account_id_or_key, with_balance, with_balance_and_cba, options)
      end
    end

    def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
      if search_key.present?
        find_in_batches_by_search_key(search_key, offset, limit, true, false, options)
      else
        find_in_batches(offset, limit, true, false, options)
      end
    end

    def balance_to_money
      Kaui::Base.to_money(account_balance.abs, currency)
    end

    def cba_to_money
      Kaui::Base.to_money(account_cba.abs, currency)
    end

    def persisted?
      !account_id.blank?
    end
  end
end
