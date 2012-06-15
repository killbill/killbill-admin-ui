require 'active_model'

class Kaui::Payment < Kaui::Base
  define_attr :invoice_id
  define_attr :amount
  define_attr :refund_amount
  define_attr :currency
  define_attr :payment_id
  define_attr :external_payment_id
  define_attr :payment_attempt_date
  define_attr :payment_method
  define_attr :payment_method_id
  define_attr :card_type
  define_attr :requested_dt
  define_attr :effective_dt
  define_attr :status
  define_attr :bundle_keys

  def initialize(data = {})
    super(:invoice_id => data['invoiceId'],
          :amount => data['amount'],
          :refund_amount => data['refundAmount'],
          :currency => data['currency'],
          :payment_id => data['id'] || data['paymentId'],
          :external_payment_id => data['externalPaymentId'],
          :payment_attempt_date => data['paymentAttemptDate'],
          :payment_method => data['paymentMethod'],
          :payment_method_id => data['paymentMethodId'],
          :card_type => data['cardType'],
          :requested_dt => data['requestedDate'],
          :effective_dt => data['effectiveDate'],
          :status => data['status'],
          :bundle_keys => data['bundleKeys'])
  end
end