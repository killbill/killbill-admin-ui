class Kaui::PaymentMethod < Kaui::Base
  define_attr :account_id
  define_attr :is_default
  define_attr :payment_method_id
  define_attr :plugin_name

  has_one :plugin_info, Kaui::PluginInfo

  def card_type
    plugin_info.property("cardType") if plugin_info.present?
  end

  def type
    plugin_info.property("type") if plugin_info.present?
  end

  def mask_number
    plugin_info.property("maskNumber") if plugin_info.present?
  end

  def card_holder_name
    plugin_info.property("cardHolderName") if plugin_info.present?
  end

  def expiration_dt
    plugin_info.property("expirationDate") if plugin_info.present?
  end

  def baid
    plugin_info.property("baid") if plugin_info.present?
  end

  def email
    plugin_info.property("email") if plugin_info.present?
  end
end
