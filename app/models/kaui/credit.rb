class Kaui::Credit < KillBillClient::Model::Credit

  # See https://github.com/killbill/killbill/issues/262
  attr_accessor :currency

  SAMPLE_REASON_CODES = ['100 - Courtesy',
                         '101 - Billing Error',
                         '199 - OTHER']
end
