module KillBillClient
  module Model
    class PlanDetail < PlanDetailAttributes

      has_many :prices, KillBillClient::Model::PriceAttributes

    end
  end
end
