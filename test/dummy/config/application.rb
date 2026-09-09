require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
# require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"
require 'sprockets/railtie'

# Work around a JRuby 10 bug (jruby/jruby#9651): assigning to an outer local
# variable named `it` inside a block silently creates a block-local shadow
# instead of updating the outer one, so op-assignments raise NoMethodError.
# sorbet-runtime 0.6.x's signature-validation code uses `it` as a loop counter
# (T::Private::Methods::Signature#each_args_value_type), so any call to a
# sig'd method (e.g. js-routes' sig-decorated methods) crashes at load time.
# Disabling runtime checks avoids building the crashing validation wrapper.
if defined?(JRUBY_VERSION)
  require 'sorbet-runtime'
  T::Configuration.default_checked_level = :never
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
