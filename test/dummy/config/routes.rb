Rails.application.routes.draw do
  mount Kaui::Engine => "/kaui", :as => "kaui_engine"
end
