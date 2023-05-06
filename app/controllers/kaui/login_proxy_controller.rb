# frozen_string_literal: true

module Kaui
  class LoginProxyController < Kaui::EngineController
    def check_login
      #
      # Redirect to where we come from after going through all the Kaui filters ensuring correct authentication and kb_tenant_id
      #
      redirect_to params['path']
    end
  end
end
