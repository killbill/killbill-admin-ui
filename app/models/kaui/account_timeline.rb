require 'active_model'

class Kaui::AccountTimeline < Kaui::Base
  has_one :account, Kaui::Account
  has_many :payments, Kaui::Payment
  has_many :bundles, Kaui::Bundle
  has_many :invoices, Kaui::Invoice

  def initialize(data = {})
    super(data)
  end
end
