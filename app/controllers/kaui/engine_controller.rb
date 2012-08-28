require 'kaui/error_helper'

class Kaui::EngineController < ApplicationController
  include Kaui::ErrorHelper
  # This is a semi-isolated engine (https://bibwild.wordpress.com/2012/05/10/the-semi-isolated-rails-engine/)
  # We expect that the hosting app's ApplicationController has these methods defined:
  #
  #   current_user - returns the id of the current user
end
