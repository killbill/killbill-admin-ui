class Kaui::AccountEmail < KillBillClient::Model::AccountEmailAttributes

  def self.find_all_sorted_by_account_id(account_id, audit = 'NONE', options = {})
    emails = Kaui::Account.new(:account_id => account_id).emails(audit, options)
    emails.map { |email| Kaui::AccountEmail.new(email.to_hash) }.sort
  end

  def <=>(account_email)
    if account_email.nil?
      -1
    elsif account_email.email.nil?
      email.nil? ? 0 : 1
    else
      email.to_s <=> account_email.email.to_s
    end
  end
end
