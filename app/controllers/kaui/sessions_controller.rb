module Kaui
  # Subclassed to specify the correct layout
  class SessionsController < Devise::SessionsController
    layout Kaui.config[:layout]
  end
end
