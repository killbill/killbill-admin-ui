require 'active_model'

class Kaui::PluginInfoProperty < Kaui::Base
  define_attr :key
  define_attr :value
  define_attr :is_updatable

  def initialize(data = {})
    super(:key => data['key'],
          :value => data['value'],
          :is_updatable => data['isUpdatable'])
  end
end