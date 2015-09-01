class Kaui::Payment < KillBillClient::Model::Payment

  attr_accessor :payment_date

  SAMPLE_REASON_CODES = ['600 - Alt payment method',
                         '699 - OTHER']

  def self.build_from_raw_payment(raw_payment)
    result = Kaui::Payment.new
    KillBillClient::Model::PaymentAttributes.instance_variable_get('@json_attributes').each do |attr|
      result.send("#{attr}=", raw_payment.send(attr))
    end
    result
  end

  def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
    if search_key.present?
      find_in_batches_by_search_key(search_key, offset, limit, options)
    else
      find_in_batches(offset, limit, options)
    end
  end

  [:auth, :captured, :purchased, :refunded, :credited].each do |type|
    define_method "#{type}_amount_to_money" do
      Kaui::Base.to_money(send("#{type}_amount"), currency)
    end
  end

  def paid_amount_to_money
    captured_amount_to_money + purchased_amount_to_money
  end

  # TODO Better name?
  def returned_amount_to_money
    refunded_amount_to_money + credited_amount_to_money
  end

  def is_fully_refunded?
    refunded_amount == captured_amount || refunded_amount == purchased_amount
  end
end
