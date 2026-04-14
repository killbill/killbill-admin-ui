module KillBillClient
  module Model
    class Phase < PhaseAttributes

      has_many :prices, KillBillClient::Model::PriceAttributes
      has_many :fixed_prices, KillBillClient::Model::PriceAttributes
      has_one :duration, KillBillClient::Model::DurationAttributes
    end
  end
end
