# frozen_string_literal: true

module Kaui
  module MoneyHelper
    def currencies
      (Money::Currency.table.map { |c| c[1][:iso_code] } + ['BTC']).sort.uniq
    end
  end
end
