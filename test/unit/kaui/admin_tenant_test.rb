require 'test_helper'

class Kaui::AdminTenantTest < ActiveSupport::TestCase

  PLUGINS_INFO = '[{"bundleSymbolicName":"org.kill-bill.billing.plugin.java.analytics-plugin","pluginKey":"analytics","pluginName":"analytics-plugin","version":"5.0.3","state":"RUNNING","isSelectedForStart":true,"services":[{"serviceTypeName":"javax.servlet.Servlet","registrationName":"killbill-analytics"}]},{"bundleSymbolicName":"org.kill-bill.billing.plugin.java.killbill-email-notifications-plugin","pluginKey":"killbill-email-notifications","pluginName":"killbill-email-notifications","version":"0.3.1-SNAPSHOT","state":"RUNNING","isSelectedForStart":true,"services":[{"serviceTypeName":"javax.servlet.Servlet","registrationName":"killbill-email-notifications"}]},{"bundleSymbolicName":"org.kill-bill.billing.killbill-platform-osgi-bundles-jruby-2","pluginKey":"kpm","pluginName":"killbill-kpm","version":"1.2.3","state":"RUNNING","isSelectedForStart":true,"services":[{"serviceTypeName":"javax.servlet.Servlet","registrationName":"killbill-kpm"}]},{"bundleSymbolicName":null,"pluginKey":"paypal","pluginName":"killbill-paypal-express","version":"5.0.7","state":"STOPPED","isSelectedForStart":true,"services":[]}]'

  test 'can split camel dash underscore space strings' do
    adminTenantController = Kaui::AdminTenantsController.new

    string = 'camelCaseString'
    splitted = adminTenantController.send(:split_camel_dash_underscore_space, string)
    assert_equal 3, splitted.count

    string = 'this-is-a-string-to-split'
    splitted = adminTenantController.send(:split_camel_dash_underscore_space, string)
    assert_split(splitted)

    string = 'this_is_a_string_to_split'
    splitted = adminTenantController.send(:split_camel_dash_underscore_space, string)
    assert_split(splitted)

    string = 'this is a string to split'
    splitted = adminTenantController.send(:split_camel_dash_underscore_space, string)
    assert_split(splitted)

    string = 'this-IsA string_to-split'
    splitted = adminTenantController.send(:split_camel_dash_underscore_space, string)
    assert_split(splitted)

  end

  test 'can do a fuzzy match of a plugin to suggest an already installed plugin' do
    plugins_info = plugins_info()
    adminTenantController = Kaui::AdminTenantsController.new

    %w(killbill-paypal express paypal-express pypl).each do |plugin_name|
      found_plugin, weights = adminTenantController.send(:fuzzy_match, plugin_name, plugins_info)
      assert_nil(found_plugin)
      assert_equal weights[0][:plugin_name], 'killbill-paypal-express'
    end

    plugin_name = 'email'
    found_plugin, weights = adminTenantController.send(:fuzzy_match, plugin_name, plugins_info)
    assert_nil(found_plugin)
    assert_equal weights[0][:plugin_name], 'killbill-email-notifications'

  end

  private

  def plugins_info
    plugins_info = []
    hash_plugin_info = JSON.parse(PLUGINS_INFO)
    hash_plugin_info.each { |plugin| plugins_info << KillBillClient::Model::PluginInfoAttributes.new(plugin)}
    plugins_info
  end

  def assert_split(splitted)
    assert_equal 6, splitted.count
    assert_equal 'this', splitted[0]
    assert_equal 'is', splitted[1]
    assert_equal 'a', splitted[2]
    assert_equal 'string', splitted[3]
    assert_equal 'to', splitted[4]
    assert_equal 'split', splitted[5]
  end
end