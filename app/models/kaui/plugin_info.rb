require 'active_model'

class Kaui::PluginInfo < Kaui::Base
  define_attr :external_payment_id

  has_many :properties, Kaui::PluginInfoProperty

  def property(key)
    prop = properties.find { |prop| prop.key == key } unless properties.nil?
    prop.value unless prop.nil?
  end
end