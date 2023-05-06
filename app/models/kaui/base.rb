# frozen_string_literal: true

module Kaui
  class Base
    def self.to_money(amount, currency)
      if currency.present?
        begin
          return Money.from_amount(amount.to_f, currency)
        rescue StandardError => _e
          # Pass through
        end
      end
      Money.from_amount(amount.to_f, 'USD')
    end
  end
end
