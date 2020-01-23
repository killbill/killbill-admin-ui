module Kaui
  module PaymentMethodHelper

    def is_json?(value)
      result = JSON.parse(value)
      result.is_a?(Hash) || result.is_a?(Array)
    rescue JSON::ParserError, TypeError
      false
    end
  end
end
