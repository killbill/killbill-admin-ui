module KillBillClient
  module Model
    class OverdueCondition < OverdueConditionAttributes

      has_one :time_since_earliest_unpaid_invoice_equals_or_exceeds, KillBillClient::Model::DurationAttributes

    end
  end
end

