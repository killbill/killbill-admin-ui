module KillBillClient
  module Model
    class InvoicePayment < InvoicePaymentAttributes

      include KillBillClient::Model::CustomFieldHelper
      include KillBillClient::Model::TagHelper
      include KillBillClient::Model::AuditLogWithHistoryHelper

      KILLBILL_API_INVOICE_PAYMENTS_PREFIX = "#{KILLBILL_API_PREFIX}/invoicePayments"

      has_many :transactions, KillBillClient::Model::Transaction
      has_many :payment_attempts, KillBillClient::Model::PaymentAttemptAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog

      has_custom_fields KILLBILL_API_INVOICE_PAYMENTS_PREFIX, :payment_id
      has_tags KILLBILL_API_INVOICE_PAYMENTS_PREFIX, :payment_id

      has_audit_logs_with_history KILLBILL_API_INVOICE_PAYMENTS_PREFIX, :payment_id

      class << self
        def find_by_id(payment_id, with_plugin_info = false, with_attempts = false, options = {})
          get "#{KILLBILL_API_INVOICE_PAYMENTS_PREFIX}/#{payment_id}",
              {
                  :withAttempts => with_attempts,
                  :withPluginInfo => with_plugin_info
              },
              options
        end

        def refund(payment_id, amount, adjustments = nil, user = nil, reason = nil, comment = nil, options = {})
          payload             = InvoicePaymentTransactionAttributes.new
          payload.amount      = amount
          payload.is_adjusted = !adjustments.nil?
          payload.adjustments = adjustments

          invoice_payment = post "#{KILLBILL_API_INVOICE_PAYMENTS_PREFIX}/#{payment_id}/refunds",
                                 payload.to_json,
                                 {},
                                 {
                                     :user    => user,
                                     :reason  => reason,
                                     :comment => comment,
                                 }.merge(options)

          invoice_payment.refresh(options)
        end

        def chargeback(payment_id, amount, currency, effective_date = nil, user = nil, reason = nil, comment = nil, options = {})
          payload                          = InvoicePaymentTransactionAttributes.new
          payload.amount                   = amount
          payload.currency                 = currency
          payload.effective_date           = effective_date

          invoice_payment = post "#{KILLBILL_API_INVOICE_PAYMENTS_PREFIX}/#{payment_id}/chargebacks",
                                 payload.to_json,
                                 {},
                                 {
                                     :user    => user,
                                     :reason  => reason,
                                     :comment => comment,
                                 }.merge(options)
          invoice_payment.refresh(options)
        end

        def chargeback_reversal(payment_id, transaction_external_key, effective_date = nil, user = nil, reason = nil, comment = nil, options = {})
          payload                          = InvoicePaymentTransactionAttributes.new
          payload.transaction_external_key = transaction_external_key
          payload.effective_date           = effective_date

          invoice_payment = post "#{KILLBILL_API_INVOICE_PAYMENTS_PREFIX}/#{payment_id}/chargebackReversals",
                                 payload.to_json,
                                 {},
                                 {
                                     :user    => user,
                                     :reason  => reason,
                                     :comment => comment,
                                 }.merge(options)
          invoice_payment.refresh(options)
        end

        def complete_invoice_payment_transaction(payment_id, user, reason, comment, options)
          invoice_payment = PaymentTransactionAttributes.new
          invoice_payment.payment_id = payment_id

          put "#{KILLBILL_API_INVOICE_PAYMENTS_PREFIX}/#{payment_id}",
              invoice_payment.to_json,
              {},
              {
                  :user => user,
                  :reason => reason,
                  :comment => comment
              }.merge(options)
        end
      end

      def create(external_payment = false, user = nil, reason = nil, comment = nil, options = {})
        created_invoice_payment = self.class.post "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/#{target_invoice_id}/payments",
                                                  to_json,
                                                  {
                                                      :externalPayment => external_payment
                                                  },
                                                  {
                                                      :user    => user,
                                                      :reason  => reason,
                                                      :comment => comment,
                                                  }.merge(options)
        created_invoice_payment.refresh(options)
      end

      def bulk_create(external_payment = false, payment_method_id = nil, target_date = nil, user = nil, reason = nil, comment = nil, options = {})
        # Nothing to return (nil)
        self.class.post "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/invoicePayments",
                        {},
                        {
                            :externalPayment => external_payment,
                            :paymentAmount   => purchased_amount,
                            :paymentMethodId => payment_method_id,
                            :targetDate => target_date
                        },
                        {
                            :user    => user,
                            :reason  => reason,
                            :comment => comment,
                        }.merge(options)
      end
    end
  end
end
