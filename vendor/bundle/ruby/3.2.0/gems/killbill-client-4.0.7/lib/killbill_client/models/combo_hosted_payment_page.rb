module KillBillClient
  module Model
    class ComboHostedPaymentPage < ComboHostedPaymentPageAttributes

      def build_form_descriptor(user = nil, reason = nil, comment = nil, options = {})
        self.class.post "#{HostedPaymentPage::KILLBILL_API_HPP_PREFIX}/hosted/form",
                        to_json,
                        {},
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
