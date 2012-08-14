# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Mock killbill-server and serve data from the fixtures
module Kaui::KillbillHelper
  @@fixtures ||= {}

  def self.get_account(account_id)
    @@fixtures.each do |k,v|
      next unless k == "accounts"
      v.each do |w,u|
        return Kaui::Account.new(u.fixture) if u.fixture["accountId"] == account_id
      end
    end

    return nil
  end

  def self.get_payment_methods(account_id)
    []
  end

  def self.get_bundles(account_id)
    []
  end

  def self.get_subscriptions_for_bundle(bundle_id)
    []
  end

  def self.set_fixtures(f)
    @@fixtures = f
  end
end

class ActiveRecord::Fixtures
  # Monkey-patch the create_fixtures method not to rely on a database
  def self.create_fixtures(fixtures_directory, table_names, class_names = {})
    table_names = [table_names].flatten.map { |n| n.to_s }
    table_names.each { |n|
      class_names[n.tr('/', '_').to_sym] = n.classify if n.include?('/')
    }

    unless table_names.empty?
      fixtures_map = {}
      table_names.map do |path|
        table_name = path.tr '/', '_'
        fixtures_map[path] = ActiveRecord::Fixtures.new(nil,
                                                        table_name,
                                                        class_names[table_name.to_sym] || table_name.classify,
                                                        ::File.join(fixtures_directory, path))
      end

      all_loaded_fixtures.update(fixtures_map)
      cache_fixtures(nil, fixtures_map)

      Kaui::KillbillHelper.set_fixtures fixtures_map
    end
    cached_fixtures(nil, table_names)
  end
end

class ActiveRecord::Fixture
  def find
    @fixture
  end
end