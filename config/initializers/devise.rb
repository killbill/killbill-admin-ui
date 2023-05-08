# frozen_string_literal: true

# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
Devise.setup do |config|
  require 'devise/orm/active_record'
  config.authentication_keys = [:kb_username]
  config.skip_session_storage = [:http_auth]
  config.timeout_in = 20.minutes
  config.sign_out_via = :delete

  config.warden do |manager|
    manager.default_strategies(scope: :user).unshift :killbill_jwt, :killbill_authenticatable
  end

  config.router_name = :kaui_engine

  # Secret key is required for devise > 3.4
  config.secret_key = '5131c6fe85c000847beb5a9207fc63711ef61e8064cc56c27ac580d9fef70ddd3de6914c79e5876dfe8e2f1a882f079c85b49ff1fc1b186e1c538dda1ad601f6'
end

module Devise
  class FailureApp < ActionController::Metal
    def scope_url
      opts = {}

      # Initialize script_name with nil to prevent infinite loops in
      # authenticated mounted engines in rails 4.2 and 5.0
      opts[:script_name] = nil

      route = route(scope)

      opts[:format] = request_format unless skip_format?

      # Fix for Rails 5.1
      # See https://github.com/rails/rails/pull/29898/files (merge_script_names)
      # opts[:script_name] = relative_url_root if relative_url_root?
      opts[:script_name] = "#{relative_url_root}/" if relative_url_root?

      router_name = Devise.mappings[scope].router_name || Devise.available_router_name
      context = send(router_name)

      if context.respond_to?(route)
        context.send(route, opts)
      elsif respond_to?(:root_url)
        root_url(opts)
      else
        '/'
      end
    end
  end
end
