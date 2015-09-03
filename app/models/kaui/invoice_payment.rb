class Kaui::InvoicePayment < KillBillClient::Model::InvoicePayment

  include Kaui::PaymentState

  SAMPLE_REASON_CODES = ['600 - Alt payment method',
                         '699 - OTHER']

  def self.build_from_raw_payment(raw_payment)
    result = Kaui::InvoicePayment.new
    KillBillClient::Model::InvoicePaymentAttributes.instance_variable_get('@json_attributes').each do |attr|
      result.send("#{attr}=", raw_payment.send(attr))
    end
    result
  end

  [:auth, :captured, :purchased, :refunded, :credited].each do |type|
    define_method "#{type}_amount_to_money" do
      Kaui::Base.to_money(send("#{type}_amount"), currency)
    end
  end
end
