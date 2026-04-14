module KillBillClient
  module Model
    class AccountTimeline < AccountTimelineAttributes

      has_one :account, KillBillClient::Model::Account
      has_many :payments, KillBillClient::Model::InvoicePayment
      has_many :bundles, KillBillClient::Model::Bundle
      has_many :invoices, KillBillClient::Model::Invoice

      class << self
        def find_by_account_id(account_id, audit = 'MINIMAL', options = {})
          get "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/timeline",
              {
                :audit => audit
              },
              options
        end
      end
    end
  end
end
