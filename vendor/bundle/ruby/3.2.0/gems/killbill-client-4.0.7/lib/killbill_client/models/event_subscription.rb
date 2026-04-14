module KillBillClient
  module Model
    class EventSubscription < EventSubscriptionAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog
    end
  end
end
