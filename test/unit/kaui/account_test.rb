require 'test_helper'

class Kaui::AccountTest < ActiveSupport::TestCase

  test 'can convert to money' do
    account = Kaui::Account.new(:account_balance => 12.42, :account_cba => 54.32, :currency => 'USD')

    assert_equal 1242, account.balance_to_money.cents
    assert_equal 'USD', account.balance_to_money.currency_as_string

    assert_equal 5432, account.cba_to_money.cents
    assert_equal 'USD', account.cba_to_money.currency_as_string
  end
end
