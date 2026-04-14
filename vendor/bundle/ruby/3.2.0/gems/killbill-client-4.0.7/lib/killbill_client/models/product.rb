module KillBillClient
  module Model
    class Product < ProductAttributes

      has_many :plans, KillBillClient::Model::Plan

    end
  end
end
