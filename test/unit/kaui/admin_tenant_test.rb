require 'test_helper'

class Kaui::AdminTenantTest < ActiveSupport::TestCase

  include Kaui::KillbillTestHelper

  PLUGIN_REPO = '[{"plugin_key":"analytics","plugin_name":"killbill-analytics","plugin_type":"java","installed":true},{"plugin_key":"kpm","plugin_name":"killbill-kpm","plugin_type":"ruby","installed":true},{"plugin_key":"paypal-express","plugin_name":"killbill-paypal-express","plugin_type":"ruby","installed":true},
                  {"plugin_key":"killbill-email-notifications","plugin_name":"killbill-email-notifications","plugin_type":null,"installed":true},{"plugin_key":"accertify","plugin_name":"killbill-accertify","plugin_type":"java","installed":false},{"plugin_key":"adyen","plugin_name":"killbill-adyen","plugin_type":"java","installed":false},
                  {"plugin_key":"avatax","plugin_name":"killbill-avatax","plugin_type":"java","installed":false},{"plugin_key":"braintree_blue","plugin_name":"killbill-braintree_blue","plugin_type":"ruby","installed":false},{"plugin_key":"currency","plugin_name":"killbill-currency","plugin_type":"ruby","installed":false},
                  {"plugin_key":"cybersource","plugin_name":"killbill-cybersource","plugin_type":"ruby","installed":false},{"plugin_key":"dwolla","plugin_name":"killbill-dwolla","plugin_type":"java","installed":false},
                  {"plugin_key":"email-notifications","plugin_name":"killbill-email-notifications","plugin_type":"java","installed":false},{"plugin_key":"firstdata-e4","plugin_name":"killbill-firstdata-e4","plugin_type":"ruby","installed":false},{"plugin_key":"forte","plugin_name":"killbill-forte","plugin_type":"java","installed":false},
                  {"plugin_key":"litle","plugin_name":"killbill-litle","plugin_type":"ruby","installed":false},{"plugin_key":"logging","plugin_name":"killbill-logging","plugin_type":"ruby","installed":false},{"plugin_key":"orbital","plugin_name":"killbill-orbital","plugin_type":"ruby","installed":false},
                  {"plugin_key":"bridge","plugin_name":"killbill-bridge","plugin_type":"java","installed":false},{"plugin_key":"payeezy","plugin_name":"killbill-payeezy","plugin_type":"java","installed":false},{"plugin_key":"payment-retries","plugin_name":"killbill-payment-retries","plugin_type":"java","installed":false},
                  {"plugin_key":"payu-latam","plugin_name":"killbill-payu-latam","plugin_type":"ruby","installed":false},{"plugin_key":"payment-test","plugin_name":"killbill-payment-test","plugin_type":"ruby","installed":false},
                  {"plugin_key":"securenet","plugin_name":"killbill-securenet","plugin_type":"ruby","installed":false},{"plugin_key":"stripe","plugin_name":"killbill-stripe","plugin_type":"ruby","installed":false},{"plugin_key":"zendesk","plugin_name":"killbill-zendesk","plugin_type":"ruby","installed":false}]'

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

  test 'can do a fuzzy match of a plugin to suggest a plugin' do
    plugins_info = plugins_repo
    adminTenantController = Kaui::AdminTenantsController.new

    %w(killbill-paypal express paypal pay).each do |plugin_name|
      found_plugin, weights = adminTenantController.send(:fuzzy_match, plugin_name, plugins_info)
      assert_nil(found_plugin)
      assert_equal weights[0][:plugin_name], 'killbill-paypal-express'
    end

    plugin_name = 'email'
    found_plugin, weights = adminTenantController.send(:fuzzy_match, plugin_name, plugins_info)
    assert_nil(found_plugin)
    assert_equal weights[0][:plugin_name], 'killbill-email-notifications'

    %w(first firstdata firstdata_e4).each do |plugin_name|
      found_plugin, weights = adminTenantController.send(:fuzzy_match, plugin_name, plugins_info)
      assert_nil(found_plugin)
      assert_equal weights[0][:plugin_name], 'killbill-firstdata-e4'
    end

    %w(braintree brain).each do |plugin_name|
      found_plugin, weights = adminTenantController.send(:fuzzy_match, plugin_name, plugins_info)
      assert_nil(found_plugin)
      assert_equal weights[0][:plugin_name], 'killbill-braintree_blue'
    end

    # if found weights should be empty
    plugin_name = 'avatax'
    found_plugin, weights = adminTenantController.send(:fuzzy_match, plugin_name, plugins_info)
    assert_equal weights.size, 0
    assert_equal found_plugin[:plugin_name], 'killbill-avatax'

  end

  test 'should fetch proprietary plugin config' do
    tenant = create_tenant()
    assert_not_nil(tenant)

    options = build_options(tenant)
    # upload plugin configuration
    plugin_name = 'duck-plugin'
    plugin_config = 'key=value'
    Kaui::AdminTenant.upload_tenant_plugin_config(plugin_name, plugin_config, options[:username], nil, nil, options)


    plugins_config = Kaui::AdminTenant.get_tenant_plugin_config({}, options)
    assert_not_nil(plugins_config)

    plugin_info = plugins_config.split('::')
    assert_equal plugin_name, plugin_info[0]
    assert_equal plugin_config, plugin_info[1].gsub('raw_config=','')
  end

  test 'should fetch plugin config' do
    tenant = create_tenant()
    assert_not_nil(tenant)

    options = build_options(tenant)
    # upload plugin configuration
    plugin_key = 'paypal_express'
    plugin_name = 'killbill-paypal-express'
    plugin_properties = { 'signature': 'AUmv9J3knY3wGGZoAYL5LM.8OzizApMN7rxHvpXbjb13reJ2CtexMApg',
                      'login': 'joel-batista-facilitator_api1.live.com',
                      'password': 'Z93EWSRUYYHYXT3L'
    }

    plugin_config = Kaui::AdminTenant.format_plugin_config(plugin_key, 'ruby', plugin_properties)
    Kaui::AdminTenant.upload_tenant_plugin_config(plugin_name, plugin_config, options[:username], nil, nil, options)


    plugins_config = Kaui::AdminTenant.get_tenant_plugin_config({ :paypal_express => { 'type' => 'ruby',
                                                                  'artifact_id' => 'paypal-express-plugin'} }, options)
    assert_not_nil(plugins_config)
    plugin_info = plugins_config.split('::')
    assert_equal plugin_key, plugin_info[0]
    response_plugin_properties = plugin_info[1].split('|')
    assert_equal plugin_properties[:signature], response_plugin_properties[0].split('=')[1]
    assert_equal plugin_properties[:login], response_plugin_properties[1].split('=')[1]
    assert_equal plugin_properties[:password], response_plugin_properties[2].split('=')[1]
  end

  private

  def plugins_repo
    plugins_info = []
    hash_plugin_info = JSON.parse(PLUGIN_REPO)
    hash_plugin_info.each do |plugin|
      plugins_info << {
          plugin_key: plugin['plugin_key'],
          plugin_name: plugin['plugin_name'],
          plugin_type: nil,
          installed: true
      }
    end
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