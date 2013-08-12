require 'kaui/error_helper'

class Kaui::EngineController < ApplicationController
  before_filter :authenticate_user!

  include Kaui::ErrorHelper

  layout :get_layout

  # Used for auditing purposes
  def current_user
    super rescue Kaui.config[:default_current_user]
  end

  protected

  def get_layout
    layout ||= Kaui.config[:layout]
  end
end
