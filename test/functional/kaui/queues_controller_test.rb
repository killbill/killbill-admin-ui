require 'test_helper'

class Kaui::QueuesControllerTest < Kaui::FunctionalTestHelper

  test 'should get queues' do
    get :index, :account_id => @account.account_id, :with_history => true
    now = assigns(:now)
    queues_entries = assigns(:queues_entries)

    assert_not_nil now
    assert_not_nil queues_entries
    assert queues_entries['busEvents'].size > 0

    assert_response :success
  end

end