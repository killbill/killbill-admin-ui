# Special base class for all the multi-tenant administrative operations which require a different set of before_filter
class Kaui::AdminEngineController < ApplicationController

  include Kaui::EngineControllerUtil

  layout :get_layout
end
