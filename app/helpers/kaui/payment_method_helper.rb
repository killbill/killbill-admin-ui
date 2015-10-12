module Kaui
  module PaymentMethodHelper

    def is_json?(string)
      !string.blank? && !!JSON.parse(string) rescue false
    end

  end
end
