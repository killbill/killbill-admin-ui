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
    find_among_fixtures(Kaui::Account, account_id)
  end

  def self.get_invoice(invoice_id)
    find_among_fixtures(Kaui::Invoice, invoice_id)
  end

  def self.get_invoice_item(invoice_id, invoice_item_id)
    find_among_fixtures(Kaui::InvoiceItem, invoice_item_id)
  end

  def self.get_bundle(bundle_id)
    find_among_fixtures(Kaui::Bundle, bundle_id)
  end

  def self.get_payments(invoice_id)
    []
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

  def self.find_among_fixtures(clazz, id)
    results = find_all_among_fixtures(clazz, id)
    results.length > 0 ? results[0] : nil
  end

  def self.find_all_among_fixtures(clazz, id)
    results = []
    type = clazz.name.demodulize.underscore
    type_id = "#{clazz.name.demodulize.camelize}Id".uncapitalize
    @@fixtures.each do |k,v|
      next unless k == "#{type}s"
      v.each do |w,u|
        results << clazz.new(u.fixture) if u.fixture[type_id] == id
      end
    end

    return results
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

class String
  def uncapitalize
    self[0, 1].downcase + self[1..-1]
  end
end