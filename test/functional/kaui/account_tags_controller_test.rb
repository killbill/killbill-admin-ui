require 'test_helper'

class Kaui::AccountTagsControllerTest < Kaui::FunctionalTestHelper

  test 'should handle Kill Bill errors when getting edit screen' do
    account_id = '1234'
    get :edit, :account_id => account_id
    assert_redirected_to account_path(account_id)
    assert_equal 'Error while communicating with the Kill Bill server: Error 404: ', flash[:error]
  end

  test 'should get edit' do
    get :edit, :account_id => @account.account_id
    assert_response 200
    assert_not_nil assigns(:account_id)
    assert_not_nil assigns(:tag_names)
    assert_not_nil assigns(:available_tags)
  end

  test 'should update tags' do
    post :update,
         :account_id => @account.account_id,
         'tag_00000000-0000-0000-0000-000000000001' => 'AUTO_PAY_OFF',
         'tag_00000000-0000-0000-0000-000000000005' => 'MANUAL_PAY',
         'tag_00000000-0000-0000-0000-000000000003' => 'OVERDUE_ENFORCEMENT_OFF'
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Account tags successfully set', flash[:notice]
  end
end
