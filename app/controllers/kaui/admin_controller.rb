class Kaui::AdminController < Kaui::EngineController

  skip_before_filter :check_for_redirect_to_tenant_screen

  def index
  end
end
