require "test_helper"

module Kaui
  class ModelTest < ActiveSupport::TestCase

    def test_full_json
      json_text = <<-EOS
        {
           "payments": [
             {
               "account": 125.0,
               "invoice_id": "the_invoice_id_1",
               "requested_dt": "2012-03-15T15:35:23.000Z",
               "effective_dt": "2012-03-15T15:35:23.000Z",
               "status": "Success",
               "payment_id": "the_payment_id_1"
             },
             {
               "account": 33.45,
               "invoice_id": "the_invoice_id_2",
               "requested_dt": "2012-03-21T15:35:23.000Z",
               "effective_dt": "2012-03-21T15:35:23.000Z",
               "status": "Success",
               "payment_id": "the_payment_id_2"
             },
             {
               "account": 75.34,
               "invoice_id": "the_invoice_id_3",
               "requested_dt": "2012-05-12T15:34:23.000Z",
               "effective_dt": "2012-05-12T15:34:23.000Z",
               "status": "Success",
               "payment_id": "the_payment_id_3"
             }
           ],
           "account": {
             "external_key": "yoyo_the_bozo",
             "account_id": "the_account_id"
           },
           "bundles": [
             {
               "external_key": "123456",
               "subscriptions": [
                 {
                   "events": [
                     {
                       "event_id": "id_create_1",
                       "billing_period": "monthly",
                       "requested_dt": "2012-03-15T15:34:22.000Z",
                       "product": "pro",
                       "effective_dt": "2012-03-15T15:34:22.000Z",
                       "price_list": "default",
                       "event_type": "CREATE",
                       "phase": "trial"
                     },
                     {
                       "event_id": "id_create_1",
                       "billing_period": "monthly",
                       "requested_dt": "2012-04-14T15:34:22.000Z",
                       "product": "pro",
                       "effective_dt": "2012-04-14T15:34:22.000Z",
                       "price_list": "default",
                       "event_type": "PHASE",
                       "phase": "evergreen"
                     },
                     {
                       "event_id": "id_create_1",
                       "billing_period": "monthly",
                       "requested_dt": "2012-05-12T15:34:22.000Z",
                       "product": "plus",
                       "effective_dt": "2012-05-12T15:34:22.000Z",
                       "price_list": "default",
                       "event_type": "CHANGE",
                       "phase": "evergreen"
                     }
                   ],
                   "subscription_id": "the_mpp_subscription_id",
                   "product_category": "MPP"
                 },
                 {
                   "events": [
                     {
                       "event_id": "id_create_2",
                       "billing_period": "monthly",
                       "requested_dt": "2012-03-21T15:34:22.000Z",
                       "product": "paid_access",
                       "effective_dt": "2012-03-21T15:34:22.000Z",
                       "price_list": "default",
                       "event_type": "CREATE",
                       "phase": "evergreen"
                     }
                   ],
                   "subscription_id": "the_ao_subscription_id",
                   "product_category": "ADDON"
                 }
               ],
               "bundle_id": "the_bundle_id_1"
             }
           ],
           "invoices": [
             {
               "amount": 125.0,
               "invoice_id": "the_invoice_id_1",
               "requested_dt": "2012-03-15T15:34:23.000Z",
               "invoice_number": "INV_0001",
               "effective_dt": "2012-03-15T15:34:23.000Z",
               "balance": 0.0
             },
             {
               "amount": 33.45,
               "invoice_id": "the_invoice_id_2",
               "requested_dt": "2012-03-21T15:34:23.000Z",
               "invoice_number": "INV_0002",
               "effective_dt": "2012-03-21T15:34:23.000Z",
               "balance": 0.0
             },
             {
               "amount": 75.34,
               "invoice_id": "the_invoice_id_3",
               "requested_dt": "2012-05-12T15:34:23.000Z",
               "invoice_number": "INV_0003",
               "effective_dt": "2012-05-12T15:34:23.000Z",
               "balance": 0.0
             }
           ]
         }
      EOS
      obj = AccountTimeline.from_json(json_text)
      assert obj.is_a?(AccountTimeline)
      assert obj.account.is_a?(Account)
      assert obj.payments.is_a?(Array)
      obj.payments.each do |payment|
        payment.is_a?(Payment)
      end
      assert obj.bundles.is_a?(Array)
      obj.bundles.each do |bundle|
        bundle.is_a?(Bundle)
        assert bundle.subscriptions.is_a?(Array)
        bundle.subscriptions.each do |subscription|
          subscription.is_a?(Subscription)
        end
      end
      assert obj.invoices.is_a?(Array)
      obj.invoices.each do |invoice|
        invoice.is_a?(Invoice)
      end
      new_json = ActiveSupport::JSON.encode(obj, :root => false)
      new_obj = AccountTimeline.from_json(new_json)
      assert_equal obj, new_obj
    end
  end
end