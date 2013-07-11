require 'test_helper'


def test_regex(str)
  /Account balance/.match(str)
end

test_regex("<dt>Account balance:</dt>")


class Kaui::AccountsControllerTest < ActionController::TestCase
  fixtures :accounts

  test "should get index" do
    get :index, :use_route => 'kaui'
    assert_response :success
  end

  test "should find account by id" do
    pierre = accounts(:pierre)

    get :show, :id => pierre["accountId"], :use_route => 'kaui'
    assert_response :success
    assert_equal assigns(:account).account_id, pierre["accountId"]
  end


  test "should find correct positive balance" do
    accnt = accounts(:account_with_positive_balance)

    get :show, :id => accnt["accountId"], :use_route => 'kaui'
    assert_response :success
    assert assigns(:account).balance > 0

    #puts @response.body

    assert_select "dd" do |elements|
      elements.each do |element|
        if /span/.match(element.to_s)
          assert_select "span" do |inner|
            assert /"label label-important"/.match(inner[0].to_s)
          end
        end
      end
    end
end

test "should find correct negative balance" do
  accnt = accounts(:account_with_negative_balance)

  get :show, :id => accnt["accountId"], :use_route => 'kaui'
  assert_response :success
  assert assigns(:account).balance < 0
end

test "should find correct zero balance" do
  accnt = accounts(:account_with_zero_balance)
  get :show, :id => accnt["accountId"], :use_route => 'kaui'
  assert_response :success
  assert assigns(:account).balance == 0
end

end
