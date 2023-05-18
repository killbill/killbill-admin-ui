# frozen_string_literal: true

JsRoutes.setup do |config|
  config.module_type = 'NIL'
  config.namespace = 'Routes'
  config.prefix = ActionController::Base.relative_url_root.to_s
  config.url_links = true
end
JsRoutes.generate!
