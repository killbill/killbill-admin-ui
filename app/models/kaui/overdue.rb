class Kaui::Overdue < KillBillClient::Model::Overdue

  class << self

    def get_overdue_json(options)
      result = KillBillClient::Model::Overdue.get_tenant_overdue_config('json', options)
      result
    end

  end
end
