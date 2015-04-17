# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
Devise.setup do |config|
  require 'devise/orm/active_record'
  config.authentication_keys = [ :kb_username ]
  config.skip_session_storage = [:http_auth]
  config.timeout_in = 20.minutes
  config.sign_out_via = :delete

  config.warden do |manager|
    manager.default_strategies(:scope => :user).unshift :killbill_authenticatable
  end

  config.router_name = :kaui_engine

  # Secret key is required for devise > 3.4
  config.secret_key = '5131c6fe85c000847beb5a9207fc63711ef61e8064cc56c27ac580d9fef70ddd3de6914c79e5876dfe8e2f1a882f079c85b49ff1fc1b186e1c538dda1ad601f6'
end

module Devise
  class FailureApp < ActionController::Metal
    def scope_url
      opts  = {}
      route = :"new_#{scope}_session_url"
      opts[:format] = request_format unless skip_format?

      config = Rails.application.config

      if config.respond_to?(:relative_url_root) && config.relative_url_root.present?
        opts[:script_name] = config.relative_url_root
      end

      context = send(Devise.available_router_name)

      if context.respond_to?(route)
        context.send(route, opts)
      elsif respond_to?(:root_url)
        root_url(opts)
      else
        "/"
      end
    end
  end
end
