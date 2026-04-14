module KillBillClient
  class Railtie < Rails::Railtie
    initializer :killbill_client_set_logger do
      KillBillClient.logger = Rails.logger
    end
  end
end
