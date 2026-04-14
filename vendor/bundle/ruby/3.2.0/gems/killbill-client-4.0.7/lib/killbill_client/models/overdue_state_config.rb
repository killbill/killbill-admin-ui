module KillBillClient
  module Model
    class OverdueStateConfig < OverdueStateConfigAttributes

      has_one :condition, KillBillClient::Model::OverdueCondition

    end
  end
end

