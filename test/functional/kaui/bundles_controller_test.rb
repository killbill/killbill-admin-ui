require 'test_helper'

class Kaui::BundlesControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index, :account_id => @bundle.account_id
    assert_response 200
    assert_not_nil assigns(:account)
    assert_not_nil assigns(:bundles)
    assert_not_nil assigns(:tags_per_bundle)
  end

  test 'should get transfer' do
    get :transfer, :id => @bundle.bundle_id
    assert_response 200
    assert_not_nil assigns(:bundle)
    assert_not_nil assigns(:account)
  end

  test 'should transfer bundle default policy' do
    check_bundle_owner(@account.account_id)

    post :do_transfer,
         :id              => @bundle.bundle_id,
         :new_account_key => @account2.external_key
    assert_response 302
    assert_equal 'Bundle was successfully transferred', flash[:notice]

    check_bundle_owner(@account2.account_id)
  end

  test 'should transfer bundle immediately' do
    check_bundle_owner(@account.account_id)

    post :do_transfer,
         :id              => @bundle.bundle_id,
         :new_account_key => @account2.external_key,
         :billing_policy  => 'IMMEDIATE'
    assert_response 302
    assert_equal 'Bundle was successfully transferred', flash[:notice]

    check_bundle_owner(@account2.account_id)
  end

  private

  def check_bundle_owner(new_owner)
    assert_equal new_owner, Kaui::Bundle.find_by_external_key(@bundle.external_key, options).account_id
  end
end
