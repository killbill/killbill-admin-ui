class Kaui::AccountEmail < Kaui::Base
  define_attr :account_id
  define_attr :email

  def initialize(attributes = {})
    super(attributes)

    # We make Rails believe the id for the AccountEmail is actually the account_id
    # (this is handy for routes and form_for helpers). Make sure though to mark it as not persisted
    # (even though @id is not nil)
    @persisted = false
  end

  def self.where(conditions, options_for_klient = {})
    account_emails = Kaui::KillbillHelper.get_account_emails(conditions[:account_id], options_for_klient) || []
    return account_emails.sort unless conditions[:email].present?

    account_emails.each do |account_email|
      return account_email if account_email.email == conditions[:email]
    end
    []
  end

  def save(user = nil, reason = nil, comment = nil, options_for_klient = {})
    begin
      Kaui::KillbillHelper.add_account_email(self, user, reason, comment, options_for_klient)
      true
    rescue => e
      @errors.add(:save, "Error while trying to add an account email: #{e}")
      false
    end
  end

  def destroy(user = nil, reason = nil, comment = nil, options_for_klient = {})
    begin
      Kaui::KillbillHelper.remove_account_email(self, user, reason, comment, options_for_klient)
      true
    rescue => e
      @errors.add(:destroy, "Error while trying to delete an account email: #{e}")
    end
  end

  def id
    to_param
  end

  def to_param
    @account_id
  end

  def <=>(account_email)
    @email <=> account_email.email
  end
end
