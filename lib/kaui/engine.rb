# frozen_string_literal: true

# Dependencies
#
# Sigh. Rails autoloads the gems specified in the Gemfile and nothing else.
# We need to explicitly require all of our dependencies listed in kaui.gemspec
#
# See also https://github.com/carlhuda/bundler/issues/49

require 'js-routes'
require 'jquery-rails'
require 'jquery-ui-rails'
require 'jquery-datatables-rails'
require 'font-awesome-sass'
require 'bootstrap-sass'
require 'bootstrap-datepicker-rails'
require 'json'
require 'money-rails'
require 'killbill_client'
require 'kenui'
require 'devise'
require 'cancan'
require 'country_select'
require 'concurrent'
require 'mustache-js-rails'
require 'nokogiri'
require 'time'
require 'd3-rails'
require 'spinjs-rails'
require 'popper_js'

module Kaui
  class Engine < ::Rails::Engine
    isolate_namespace Kaui
    config.autoload_once_paths = %W[
      #{root}/app/controllers
      #{root}/app/helpers
      #{root}/app/models
    ]

    initializer 'kaui_engine.action_controller', before: :load_config_initializers do |_app|
      ActiveSupport.on_load :action_controller_base do
        helper Kaui::Engine.helpers
      end

      Kaui.thread_pool = Concurrent::ThreadPoolExecutor.new(min_threads: 10,
                                                            max_threads: 50,
                                                            idletime: 60,
                                                            max_queue: 5000,
                                                            # Explicitly throw an exception (:caller_runs can introduce weird deadlocks with Promise)
                                                            fallback_policy: :abort)
    end
  end
end
