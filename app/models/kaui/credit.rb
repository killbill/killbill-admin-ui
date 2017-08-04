class Kaui::Credit < KillBillClient::Model::Credit

  # See https://github.com/killbill/killbill/issues/262
  attr_accessor :currency
end
