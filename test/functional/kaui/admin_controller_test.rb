require 'test_helper'

class Kaui::AdminControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index
    assert_not_nil assigns(:clock)
    clock = assigns(:clock)
    assert_not_nil clock['localDate']
    assert_match /\d{4}-\d{,2}-\d{,2}/, clock['localDate']
    assert_response :success
  end

  test 'should set clock' do

    # retrieve current clock from killbill
    get :index
    assert_not_nil assigns(:clock)
    clock = assigns(:clock)
    assert_not_nil clock['localDate']
    assert_match /\d{4}-\d{,2}-\d{,2}/, clock['localDate']
    assert_response :success

    # update killbill clock
    put :set_clock, :commit => 'Submit', :new_date => clock['currentUtcTime']
    assert_response :redirect

    # reset killbill clock
    put :set_clock, :commit => nil
    assert_response :redirect

  end

end