require 'test_helper'

class Kaui::AccountEmailTest < ActiveSupport::TestCase

  test 'can compare emails' do
    email1 = Kaui::AccountEmail.new(:account_id => SecureRandom.uuid, :email => 'abc@bar.com')
    email2 = Kaui::AccountEmail.new(:account_id => SecureRandom.uuid, :email => 'bcd@bar.com')
    email3 = Kaui::AccountEmail.new(:account_id => SecureRandom.uuid, :email => nil)

    assert_equal -1, email1 <=> email2
    assert_equal 1, email2 <=> email1
    assert_equal 0, email1 <=> email1
    assert_equal 0, email2 <=> email2
    assert_equal 0, email3 <=> email3
    assert_equal 1, email1 <=> email3
    assert_equal -1, email3 <=> email1
    assert_equal -1, email1 <=> nil
  end
end
