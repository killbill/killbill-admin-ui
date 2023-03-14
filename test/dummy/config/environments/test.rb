Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true
  config.action_view.cache_template_loading = true
  config.active_record.migration_error = false

  ## Eager load code on boot. This is required to work-around an obscure bug
  # where Kaui::AccountEmail isn't loading (hangs) in the lambda of AccountsController#show
  config.eager_load = true

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.seconds.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  # config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  # config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # arjdbc is very broken on Rails 5
  # https://github.com/jruby/activerecord-jdbc-adapter/issues/780
  # https://github.com/rails/rails/commit/ae39b1a03d0a859be9d5342592c8936f89fcbacf
  if defined?(JRUBY_VERSION)
    config.active_record.migration_error = false
    config.active_record.maintain_test_schema = false
  end
end
