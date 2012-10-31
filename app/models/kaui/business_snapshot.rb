class Kaui::BusinessSnapshot < Kaui::Base
  has_one  :business_account, Kaui::BusinessAccount
  has_many :business_subscription_transitions, Kaui::BusinessSubscriptionTransition
  has_many :business_invoices, Kaui::BusinessInvoice
  has_many :business_invoice_payments, Kaui::BusinessInvoicePayment
  has_many :business_overdue_statuses, Kaui::BusinessOverdueStatus
  has_many :business_tags, Kaui::BusinessTag
  has_many :business_fields, Kaui::BusinessField
end