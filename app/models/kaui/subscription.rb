class Kaui::Subscription < Kaui::Base
  define_attr :account_id
  define_attr :subscription_id
  define_attr :bundle_id
  define_attr :product_category
  define_attr :product_name
  define_attr :billing_period
  define_attr :charged_through_date
  define_attr :price_list
  define_attr :start_date
  define_attr :canceled_date

  has_many :events, Kaui::Event

  def initialize(data = {})
    super(:account_id =>  data['accountId'] || data['account_id'],
          :subscription_id => data['subscriptionId'] || data['subscription_id'],
          :bundle_id => data['bundleId'] || data['bundle_id'],
          :product_category => data['productCategory'] || data['product_category'],
          :product_name => data['productName'] || data['product_name'],
          :billing_period => data['billingPeriod'] || data['billing_period'],
          :charged_through_date => data['chargedThroughDate'] || data['charged_through_date'],
          :price_list => data['priceList'] || data['price_list'],
          :start_date => data['startDate'] || data['start_date'],
          :canceled_date => data['cancelledDate'] || data['canceled_date'],
          :events => data['events'])
  end
end
