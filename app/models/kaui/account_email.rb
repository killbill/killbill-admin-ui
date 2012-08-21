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

  def self.where(conditions)
    begin
      account_emails = Kaui::KillbillHelper.get_account_emails(conditions[:account_id]) || []
    rescue => e
      flash[:error] = "Error while getting account emails: #{e.message} #{e.response}"
    end

    return account_emails.sort unless conditions[:email].present?

    account_emails.each do |account_email|
      return account_email if account_email.email == conditions[:email]
    end
    []
  end

  def save
    success = Kaui::KillbillHelper.add_account_email(self)
    @errors.add(:save, 'Unable to save the email') unless success
    success
  end

  def destroy
    success = Kaui::KillbillHelper.remove_account_email(self)
    @errors.add(:destroy, 'Unable to destroy the email') unless success
    success
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