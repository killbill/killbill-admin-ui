module KillBillClient
  module Model
    class HostedPaymentPage < HostedPaymentPageFieldsAttributes

      KILLBILL_API_HPP_PREFIX = "#{KILLBILL_API_PREFIX}/paymentGateways"

      def build_form_descriptor(kb_account_id, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
        query_map = {}

        query_map[:paymentMethodId] = payment_method_id unless payment_method_id.nil?

        self.class.post "#{KILLBILL_API_HPP_PREFIX}/hosted/form/#{kb_account_id}",
                        to_json,
                        query_map,
                        {
                            :user => user,
                            :reason => reason,
                            :comment => comment,
                        }.merge(options),
                        HostedPaymentPageFormDescriptorAttributes
      end
    end
  end
end
