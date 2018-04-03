require 'test_helper'

class Kaui::AdminControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index
    clock = get_date
    assert_not_nil clock
    date = DateTime.parse(clock.to_s.gsub('"','')).strftime('%F')
    assert_match(/\d{4}-\d{,2}-\d{,2}/, date)
    assert_response :success
  end

  test 'should set clock' do

    # retrieve current clock from killbill
    get :index

    clock = get_date
    assert_not_nil clock
    date = DateTime.parse(clock.to_s.gsub('"','')).strftime('%F')
    assert_match(/\d{4}-\d{,2}-\d{,2}/, date)
    assert_response :success

    # update killbill clock
    put :set_clock, :commit => 'Submit', :new_date => clock
    assert_response :redirect

    # reset killbill clock
    put :set_clock, :commit => nil
    assert_response :redirect

  end

  private

  def get_date
    return nil if @response.nil? || @response.body.nil?

    pattern = Regexp.new('<span.id="kb_clock">(?<clock>.+?)</span>')
    data = pattern.match(@response.body)
    data.nil? ? nil : data[:clock]
  end

end