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

  define_attr :account_id
  define_attr :external_key
  define_attr :payment_id
  define_attr :invoice_id
  define_attr :amount
  define_attr :comment
  define_attr :reason
end