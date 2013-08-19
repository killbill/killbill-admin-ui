# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require 'securerandom'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load helpers
Dir["#{File.dirname(__FILE__)}/unit/helpers/kaui/*.rb"].each { |f| require f }

# Include Devise helpers
class ActionController::TestCase
  include Devise::TestHelpers

  setup do
    @user = Kaui::User.create!({
                                 :kb_tenant_id => "tenant_id_test",
                                 :kb_username => "username_test",
                                 :kb_session_id => "session_id_test"
                               })
    sign_in @user
  end
end

module Kaui
  class User < ActiveRecord::Base

    private

    def self.do_find_permissions(options = {})
      ["*:*"]
    end
  end
end

# Mock killbill-server and serve data from the fixtures
module Kaui::KillbillHelper
  @@fixtures ||= {}

  def self.get_account_by_key_with_balance_and_cba(key, options = {})
    self.get_account_by_key(key, false, true, options)
  end

  def self.get_account(account_id, with_balance = false, with_balance_and_cba = false, options = {})
    find_among_fixtures(Kaui::Account, account_id)
  end

  def self.get_account_emails(account_id, options = {})
    []
  end

  def self.get_account_by_external_key(account_id, with_balance = false, with_balance_and_cba = false, options = {})
    find_among_fixtures(Kaui::Account, account_id)
  end

  def self.get_overdue_state_for_bundle(bundle_id, options = {})
    find_among_fixtures(Kaui::OverdueState, bundle_id)
  end

  def self.get_invoice(invoice_id, with_items = true, options = {})
    find_among_fixtures(Kaui::Invoice, invoice_id)
  end

  def self.get_invoice_item(invoice_id, invoice_item_id, options = {})
    find_among_fixtures(Kaui::InvoiceItem, invoice_item_id)
  end

  def self.get_bundle(bundle_id, options = {})
    find_among_fixtures(Kaui::Bundle, bundle_id)
  end

  def self.get_payments(invoice_id, options = {})
    []
  end

  def self.get_payment_methods(account_id, options = {})
    []
  end

  def self.get_bundles(account_id, options = {})
    []
  end

  def self.get_subscriptions_for_bundle(bundle_id, options = {})
    []
  end

  def self.get_tags_for_account(account_id, options = {})
    []
  end

  def self.get_tag_definitions(options = {})
    find_all_among_fixtures(Kaui::TagDefinition)
  end

  def self.get_tag_definition(tag_definition_id, options = {})
    find_among_fixtures(Kaui::TagDefinition, tag_definition_id, 'id')
  end

  def self.create_tag_definition(tag_definition, options = {})
    tag_definition.id = SecureRandom.uuid
    add_fixture(tag_definition, Kaui::TagDefinition)
  end

  def self.delete_tag_definition(tag_definition_id, options = {})
    delete_fixture(Kaui::TagDefinition, tag_definition_id, 'id')
  end

  def self.find_among_fixtures(clazz, id, type_id=nil)
    results = find_all_among_fixtures(clazz, id, type_id)
    results.length > 0 ? results[0] : nil
  end

  def self.find_all_among_fixtures(clazz, id=nil, type_id=nil)
    results = []
    type = clazz.name.demodulize.underscore
    type_id = "#{clazz.name.demodulize.camelize}Id".uncapitalize unless type_id
    @@fixtures.each do |k,v|
      next unless k == "#{type}s"
      v.each do |w,u|
        results << clazz.new(u.fixture) if u.fixture[type_id] == id or !id.present?
      end
    end

    return results
  end

  def self.add_fixture(fixture, clazz)
    type = clazz.name.demodulize.underscore
    @@fixtures["#{type}s"].fixtures ||= {}
    @@fixtures["#{type}s"].fixtures["auto_generated_fixture_#{rand(100)}"] = ActiveRecord::Fixture.new(fixture.to_hash, clazz)
    fixture
  end

  def self.delete_fixture(clazz, id, type_id=nil)
    type = clazz.name.demodulize.underscore
    type_id = "#{clazz.name.demodulize.camelize}Id".uncapitalize unless type_id
    @@fixtures.each do |k,v|
      next unless k == "#{type}s"
      v.each do |w,u|
        v.fixtures.delete(w) if u.fixture[type_id] == id
      end
    end
  end

  def self.set_fixtures(f)
    @@fixtures = f
  end
end

class ActiveRecord::Fixtures
  require 'json'

  class File
    def rows
      return @rows if @rows

      begin
        # Note the .to_json! We want to enforce JSON-type data here,
        # which is what we get over the network when querying Killbill
        data = JSON.parse(YAML.load(render(IO.read(@file))).to_json)
      rescue *RESCUE_ERRORS => error
        raise Fixture::FormatError, "a YAML error occurred parsing #{@file}. Please note that YAML must be consistently indented using spaces. Tabs are not allowed. Please have a look at http://www.yaml.org/faq.html\nThe exact error was:\n  #{error.class}: #{error}", error.backtrace
      end
      # Skip validation since we modified the data
      @rows = data ? data.to_a : []
    end
  end

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

# See http://jira.codehaus.org/browse/JRUBY-6176
module SecureRandom
  def self.uuid
    ary = self.random_bytes(16).unpack("NnnnnN")
    ary[2] = (ary[2] & 0x0fff) | 0x4000
    ary[3] = (ary[3] & 0x3fff) | 0x8000
    "%08x-%04x-%04x-%04x-%04x%08x" % ary
  end unless respond_to?(:uuid)
end
