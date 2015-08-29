require 'test_helper'

class Kaui::HomeControllerTest < Kaui::FunctionalTestHelper

  test 'should understand search queries' do
    get :search, :q => 'John Doe'
    assert_redirected_to accounts_path(:q => 'John Doe')

    get :search, :q => 'de305d54-75b4-431b-adb2-eb6b9e546014'
    assert_redirected_to accounts_path(:q => 'de305d54-75b4-431b-adb2-eb6b9e546014')

    get :search, :q => 'invoice:de305d54-75b4-431b-adb2-eb6b9e546014'
    assert_redirected_to invoice_path(:id => 'de305d54-75b4-431b-adb2-eb6b9e546014')

    get :search, :q => 'payment:de305d54-75b4-431b-adb2-eb6b9e546014'
    assert_redirected_to payment_path(:id => 'de305d54-75b4-431b-adb2-eb6b9e546014')

    get :search, :q => 'invoice:546014'
    assert_redirected_to invoice_path(:id => '546014')

    get :search, :q => 'payment:546014'
    assert_redirected_to payment_path(:id => '546014')
  end
end
