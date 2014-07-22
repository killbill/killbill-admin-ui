require 'test_helper'

class Kaui::BundleTagsControllerTest < Kaui::FunctionalTestHelper

  test 'should show tags' do
    get :show, :bundle_id => @bundle.bundle_id
    assert_response 200
    assert_not_nil assigns(:bundle)
    assert_not_nil assigns(:tags)
  end

  test 'should get edit' do
    get :edit, :bundle_id => @bundle.bundle_id
    assert_response 200
    assert_not_nil assigns(:bundle)
    assert_not_nil assigns(:tag_names)
    assert_not_nil assigns(:available_tags)
  end

  test 'should update tags' do
    post :update,
         :bundle_id                                 => @bundle.bundle_id,
         'tag_00000000-0000-0000-0000-000000000001' => 'AUTO_PAY_OFF',
         'tag_00000000-0000-0000-0000-000000000005' => 'MANUAL_PAY',
         'tag_00000000-0000-0000-0000-000000000003' => 'OVERDUE_ENFORCEMENT_OFF'
    assert_redirected_to bundle_tags_path(:bundle_id => @bundle.bundle_id)
    assert_equal 'Bundle tags successfully set', flash[:notice]
  end
end
