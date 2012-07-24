class Kaui::Chargeback < Kaui::Base
  SAMPLE_REASON_CODES = [  "400 - Canceled Recurring Transaction",
                    "401 - Cardholder Disputes Quality of Goods or Services",
                    "402 - Cardholder Does Not Recognize Transaction",
                    "403 - Cardholder Request Due to Dispute",
                    "404 - Credit Not Processed",
                    "405 - Duplicate Processing",
                    "406 - Fraud Investigation",
                    "407 - Fraudulent Transaction - Card Absent Environment",
                    "408 - Incorrect Transaction Amount or Account Number",
                    "409 - No Cardholder Authorization",
                    "410 - Non receipt of Merchandise",
                    "411 - Not as Described or Defective Merchandise",
                    "412 - Recurring Payment",
                    "413 - Request for Copy Bearing Signature",
                    "414 - Requested Transaction Data Not Received",
                    "415 - Services Not Provided or Merchandise not Received",
                    "416 - Transaction Amount Differs",
                    "417 - Validity Challenged",
                    "418 - Unauthorized Payment",
                    "419 - Unauthorized Claim",
                    "420 - Not as Described",
                    "499 - OTHER" ]

  define_attr :payment_id
  define_attr :chargeback_amount
  define_attr :requested_dt
  define_attr :effective_dt
  define_attr :reason

  def initialize(data = {})
    super(:payment_id => data['paymentId'] || data['payment_id'],
          :chargeback_amount => data['chargebackAmount'] || data['chargeback_amount'],
          :requested_dt => data['requestedDate'] || data['requested_date'] || data['requested_dt'],
          :effective_dt => data['effectiveDate'] || data['effective_date'] || data['effective_dt'],
          :reason => data['reason'])
  end
end