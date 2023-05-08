# frozen_string_literal: true

# HACK: to make the killbill client models work as rails models

require File.expand_path('../../app/models/kaui/rails_methods.rb', __dir__)

module KillBillClient
  module Model
    Resource.class_eval do
      include Kaui::RailsMethods
    end
  end
end
