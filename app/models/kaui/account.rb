class Kaui::Account < KillBillClient::Model::Account

  def self.find_by_id_or_key(account_id_or_key, with_balance = false, with_balance_and_cba = false, options = {})
    if account_id_or_key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
      begin
        find_by_id(account_id_or_key, with_balance, with_balance_and_cba, options)
      rescue => e
        begin
          # account_id_or_key looked like an id, but maybe it's an external key (this will happen in tests)?
          find_by_external_key(account_id_or_key, with_balance, with_balance_and_cba, options)
        rescue => f
          # Nope - raise the initial exception
          raise e
        end
      end
    else
      find_by_external_key(account_id_or_key, with_balance, with_balance_and_cba, options)
    end
  end

  def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
    if search_key.present?
      find_in_batches_by_search_key(search_key, offset, limit, false, false, options)
    else
      find_in_batches(offset, limit, false, false, options)
    end
  end

  def balance_to_money
    Kaui::Base.to_money(account_balance.abs, currency)
  end

  def cba_to_money
    Kaui::Base.to_money(account_cba.abs, currency)
  end
end
