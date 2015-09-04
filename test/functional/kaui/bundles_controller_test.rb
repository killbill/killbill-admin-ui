require 'test_helper'

class Kaui::BundlesControllerTest < Kaui::FunctionalTestHelper

  test 'should be redirected if an invalid account id was specified in index screen' do
    account_id = SecureRandom.uuid.to_s
    get :index, :account_id => account_id
    assert_redirected_to account_path(account_id)
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Account does not exist for id #{account_id}", flash[:error]
  end

  test 'should get index' do
    get :index, :account_id => @bundle.account_id
    assert_response 200
    assert_not_nil assigns(:account)
    assert_not_nil assigns(:bundles)
    assert_not_nil assigns(:tags_per_bundle)
  end

  test 'should handle Kill Bill errors during transfer' do
    post :do_transfer, :id => @bundle.bundle_id
    assert_redirected_to home_path
    assert_equal 'Required parameter missing: new_account_key', flash[:error]

    new_account_key = SecureRandom.uuid.to_s
    post :do_transfer, :id => @bundle.bundle_id, :new_account_key => new_account_key
    assert_redirected_to home_path
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Account does not exist for id #{new_account_key}", flash[:error]

    bundle_id = SecureRandom.uuid.to_s
    post :do_transfer, :id => bundle_id, :new_account_key => @account2.external_key
    assert_redirected_to home_path
    assert_equal "Error while communicating with the Kill Bill server: Error 500: Object id=#{bundle_id} type=BUNDLE doesn't exist!", flash[:error]
  end

  test 'should get transfer' do
    get :transfer, :id => @bundle.bundle_id
    assert_response 200
    assert_not_nil assigns(:bundle_id)
  end

  test 'should transfer bundle default policy' do
    check_bundle_owner(@account.account_id)

    post :do_transfer,
         :id => @bundle.bundle_id,
         :new_account_key => @account2.external_key
    assert_redirected_to account_bundles_path(@account2.account_id)
    assert_equal 'Bundle was successfully transferred', flash[:notice]

    check_bundle_owner(@account2.account_id)
  end

  test 'should transfer bundle immediately' do
    check_bundle_owner(@account.account_id)

    post :do_transfer,
         :id => @bundle.bundle_id,
         :new_account_key => @account2.external_key,
         :billing_policy => 'IMMEDIATE'
    assert_redirected_to account_bundles_path(@account2.account_id)
    assert_equal 'Bundle was successfully transferred', flash[:notice]

    check_bundle_owner(@account2.account_id)
  end

  test 'should expose restful endpoint' do
    get :restful_show, :id => @bundle.bundle_id
    assert_redirected_to account_bundles_path(@bundle.account_id)

    get :restful_show, :id => @bundle.external_key
    assert_redirected_to account_bundles_path(@bundle.account_id)
  end

  private

  def check_bundle_owner(new_owner)
    assert_equal new_owner, Kaui::Bundle.find_by_external_key(@bundle.external_key, options).account_id
  end
end
