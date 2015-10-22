module Kaui
  module ApplicationHelper

    def tenant_selected?
      session[:kb_tenant_id].present?
    end
  end
end
