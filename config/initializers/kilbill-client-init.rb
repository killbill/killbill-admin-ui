# hack to make the killbillclient models work as rails models

module KillBillClient
  module Model
    Resource.class_eval do
      include Kaui::RailsMethods
    end
  end
end
