module Kaui
  class Engine < ::Rails::Engine
    isolate_namespace Kaui

    initializer 'kaui_engine.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper Kaui::DateHelper
      end
    end
  end
end
