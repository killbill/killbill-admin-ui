require 'active_model'

class Kaui::Refund < Kaui::Base
  SAMPLE_REASON_CODES = [ "500 - Courtesy",
                          "501 - Billing Error",
                          "502 - Alt payment method",
                          "599 - OTHER" ]

  define_attr :refund_id
  define_attr :adjusted
  define_attr :refund_amount

  def initialize(data = {})
    super(:refund_id => data['refundId'] || data['refund_id'],
          :adjusted => data['adjusted'],
          :refund_amount => data['refundAmount'] || data['refund_amount'])
  end
end