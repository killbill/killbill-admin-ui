class Kaui::Subscription < Kaui::Base
  define_attr :subscription_id
  define_attr :bundle_id
  define_attr :product_category
  define_attr :product_name
  define_attr :billing_period
  define_attr :charged_through_date
  define_attr :price_list
  define_attr :start_date
  define_attr :canceledDate
  has_many :events, Kaui::Event

  def initialize(data = {})
    super(:subscription_id => data['subscriptionId'],
          :bundle_id => data['bundleId'],
          :product_category => data['productCategory'],
          :product_name => data['productName'],
          :billing_period => data['billingPeriod'],
          :charged_through_date => data['chargedThroughDate'],
          :price_list => data['priceList'],
          :start_date => data['startDate'],
          :canceledDate => data['cancelledDate'],
          :events => data['events'])
  end
end
