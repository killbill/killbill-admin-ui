# hack to make the killbill client models work as rails models

module KillBillClient
  module Model
    Resource.class_eval do
      include Kaui::RailsMethods
    end
  end
end
