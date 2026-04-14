module KillBillClient
  module Model
    class Invoice < InvoiceAttributes

      include KillBillClient::Model::CustomFieldHelper
      include KillBillClient::Model::TagHelper
      include KillBillClient::Model::AuditLogWithHistoryHelper

      KILLBILL_API_INVOICES_PREFIX = "#{KILLBILL_API_PREFIX}/invoices"
      KILLBILL_API_DRY_RUN_INVOICES_PREFIX = "#{KILLBILL_API_INVOICES_PREFIX}/dryRun"

      has_many :audit_logs, KillBillClient::Model::AuditLog
      has_many :items, KillBillClient::Model::InvoiceItem
      has_many :credits, KillBillClient::Model::InvoiceItem

      has_custom_fields KILLBILL_API_INVOICES_PREFIX, :invoice_id
      has_tags KILLBILL_API_INVOICES_PREFIX, :invoice_id
      has_audit_logs_with_history KILLBILL_API_INVOICES_PREFIX, :invoice_id


      class << self
        def find_by_id(invoice_id, with_children_items = false, audit = "NONE", options = {})
          get "#{KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}",
              {
                  :withChildrenItems => with_children_items,
                  :audit     => audit
              },
              options
        end

        def find_by_number(number, with_children_items = false, audit = "NONE", options = {})
          get "#{KILLBILL_API_INVOICES_PREFIX}/byNumber/#{number}",
              {
                  :withChildrenItems => with_children_items,
                  :audit     => audit
              },
              options
        end

        def find_by_invoice_item_id(invoice_item_id, with_children_items = false, audit = "NONE", options = {})
          get "#{KILLBILL_API_INVOICES_PREFIX}/byItemId/#{invoice_item_id}",
              {
                  :withChildrenItems => with_children_items,
                  :audit     => audit
              },
              options
        end

        def find_in_batches(offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_INVOICES_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_INVOICES_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end

        def as_html(invoice_id, options = {})
          get "#{KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}/html",
              {},
              {
                  :accept => 'text/html'
              }.merge(options)
        end

        def trigger_invoice(account_id, target_date, user = nil, reason = nil, comment = nil, options = {})
          query_map              = {:accountId => account_id}
          query_map[:targetDate] = target_date if !target_date.nil?

          begin
            res = post "#{KILLBILL_API_INVOICES_PREFIX}/",
                       {},
                       query_map,
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options),
                       Invoice

            res.refresh(options)

          rescue KillBillClient::API::BadRequest
            # No invoice to generate : TODO parse json to verify this is indeed the case
          end
        end

        def trigger_invoice_dry_run(account_id, target_date, upcoming_invoice_target_date, plugin_property = [], user = nil, reason = nil, comment = nil, options = {})

          dry_run = InvoiceDryRunAttributes.new
          dry_run.dry_run_type = upcoming_invoice_target_date ? 'UPCOMING_INVOICE' : 'TARGET_DATE'

          query_map = {:accountId => account_id}
          query_map[:targetDate] = target_date if target_date != nil
          query_map[:pluginProperty] = plugin_property unless plugin_property.empty?

          res = post "#{KILLBILL_API_DRY_RUN_INVOICES_PREFIX}",
                     dry_run.to_json,
                     query_map,
                     {
                         :user => user || 'trigger_invoice_dry_run',
                         :reason => reason,
                         :comment => comment,
                     }.merge(options),
                     Invoice


          nothing_to_generate?(res) ? nil : res.refresh(options)

        end


        def create_subscription_dry_run(account_id, bundle_id, target_date, product_name, product_category,
                                        billing_period, price_list_name,  options = {})
          query_map              = {:accountId => account_id}
          query_map[:targetDate] = target_date if !target_date.nil?

          dry_run = InvoiceDryRunAttributes.new
          dry_run.dry_run_type = 'SUBSCRIPTION_ACTION'
          dry_run.dry_run_action = 'START_BILLING'
          dry_run.product_name = product_name
          dry_run.product_category = product_category
          dry_run.billing_period = billing_period
          dry_run.price_list_name = price_list_name
          dry_run.bundle_id = bundle_id

          res = post "#{KILLBILL_API_DRY_RUN_INVOICES_PREFIX}",
                     dry_run.to_json,
                     query_map,
                     {
                         :user    => 'create_subscription_dry_run',
                         :reason  => '',
                         :comment => '',
                     }.merge(options),
                     Invoice

          nothing_to_generate?(res) ? nil : res.refresh(options)

        end

        def change_plan_dry_run(account_id, bundle_id, subscription_id, target_date, product_name, product_category, billing_period, price_list_name,
                                effective_date, billing_policy, options = {})
          query_map              = {:accountId => account_id}
          query_map[:targetDate] = target_date if !target_date.nil?

          dry_run = InvoiceDryRunAttributes.new
          dry_run.dry_run_type = 'SUBSCRIPTION_ACTION'
          dry_run.dry_run_action = 'CHANGE'
          dry_run.product_name = product_name
          dry_run.product_category = product_category
          dry_run.billing_period = billing_period
          dry_run.price_list_name = price_list_name
          dry_run.effective_date = effective_date
          dry_run.billing_policy = billing_policy
          dry_run.bundle_id = bundle_id
          dry_run.subscription_id = subscription_id


          res = post "#{KILLBILL_API_DRY_RUN_INVOICES_PREFIX}",
                     dry_run.to_json,
                     query_map,
                     {
                         :user    => 'change_plan_dry_run',
                         :reason  => '',
                         :comment => '',
                     }.merge(options),
                     Invoice

          nothing_to_generate?(res) ? nil : res.refresh(options)

        end


        def cancel_subscription_dry_run(account_id, bundle_id, subscription_id, target_date,
                                        effective_date, billing_policy,  options = {})
          query_map              = {:accountId => account_id}
          query_map[:targetDate] = target_date if !target_date.nil?

          dry_run = InvoiceDryRunAttributes.new
          dry_run.dry_run_type = 'SUBSCRIPTION_ACTION'
          dry_run.dry_run_action = 'STOP_BILLING'
          dry_run.effective_date = effective_date
          dry_run.billing_policy = billing_policy
          dry_run.bundle_id = bundle_id
          dry_run.subscription_id = subscription_id


          res = post "#{KILLBILL_API_DRY_RUN_INVOICES_PREFIX}",
                     dry_run.to_json,
                     query_map,
                     {
                         :user    => 'cancel_subscription_dry_run',
                         :reason  => '',
                         :comment => '',
                     }.merge(options),
                     Invoice

          nothing_to_generate?(res) ? nil : res.refresh(options)

        end


        def get_invoice_template(is_manual_pay, locale = nil, options = {})

          require_multi_tenant_options!(options, "Retrieving an invoice template supported in multi-tenant mode")
          locale ||= 'en'

          get "#{KILLBILL_API_INVOICES_PREFIX}/#{is_manual_pay ? "manualPayTemplate/#{locale}" : "template"}",
              {},
              {
                  :head => {'Accept' => 'text/html'},
              }.merge(options)
        end

        def upload_invoice_template(invoice_template, is_manual_pay, delete_if_exists, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading a invoice template is only supported in multi-tenant mode")


          params                  = {}
          params[:deleteIfExists] = delete_if_exists if delete_if_exists

          post "#{KILLBILL_API_INVOICES_PREFIX}/#{is_manual_pay ? "manualPayTemplate" : "template"}",
               invoice_template,
               params,
               {
                   :head => {'Accept' => 'text/html'},
                   :content_type => 'text/html',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
          get_invoice_template(is_manual_pay, nil, options)
        end

        def get_invoice_translation(locale, options = {})

          require_multi_tenant_options!(options, "Retrieving an invoice translation supported in multi-tenant mode")


          get "#{KILLBILL_API_INVOICES_PREFIX}/translation/#{locale}",
              {},
              {
                  :head => {'Accept' => 'text/plain'},
              }.merge(options)
        end

        def upload_invoice_translation(invoice_translation, locale, delete_if_exists, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading a invoice translation is only supported in multi-tenant mode")


          params                  = {}
          params[:deleteIfExists] = delete_if_exists if delete_if_exists

          post "#{KILLBILL_API_INVOICES_PREFIX}/translation/#{locale}",
               invoice_translation,
               params,
               {
                   :head => {'Accept' => 'text/plain'},
                   :content_type => 'text/plain',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
          get_invoice_translation(locale, options)
        end


        def get_catalog_translation(locale, options = {})

          require_multi_tenant_options!(options, "Retrieving a catalog translation is only supported in multi-tenant mode")

          get "#{KILLBILL_API_INVOICES_PREFIX}/catalogTranslation/#{locale}",
              {},
              {
                  :head => {'Accept' => 'text/plain'},
              }.merge(options)
        end

        def upload_catalog_translation(catalog_translation, locale, delete_if_exists, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading a catalog translation is only supported in multi-tenant mode")

          params                  = {}
          params[:deleteIfExists] = delete_if_exists if delete_if_exists

          post "#{KILLBILL_API_INVOICES_PREFIX}/catalogTranslation/#{locale}",
               catalog_translation,
               params,
               {
                   :head => {'Accept' => 'text/plain'},
                   :content_type => 'text/plain',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
          get_catalog_translation(locale, options)
        end

        def create_migration_invoice(account_id, invoices, target_date, user = nil, reason = nil, comment = nil, options = {})

          params = {}
          params[:targetDate] = target_date
          post "#{KILLBILL_API_INVOICES_PREFIX}/migration/#{account_id}",
               invoices.to_json,
               params,
               {
                   :user    => user,
                   :reason  => reason,
                   :comment => comment,
               }.merge(options)
        end

        def trigger_invoice_group_run(account_id, target_date = nil, plugin_property = nil, user = nil, reason = nil, comment = nil, options = {})
          query_map              = {:accountId => account_id}
          query_map[:targetDate] = target_date if !target_date.nil?
          query_map[:pluginProperty] = plugin_property if !plugin_property.nil?

          res = post "#{KILLBILL_API_INVOICES_PREFIX}/group",
                      {},
                      query_map,
                      {
                          :user    => user,
                          :reason  => reason,
                          :comment => comment,
                      }.merge(options)
        end

        def retrieve_invoice_group(account_id, group_id, with_children_items = false, audit = "NONE", options = {})
          res = get "#{KILLBILL_API_INVOICES_PREFIX}/#{group_id}/group",
                      {
                        :accountId => account_id,
                        :withChildrenItems => with_children_items,
                        :audit => audit
                      },
                      options
        end

        def retrieve_payments_for_invoice(invoice_id, with_plugin_info = false, with_attempts = false, audit = "NONE", options = {})
          res = get "#{KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}/payments",
                      {
                        :withPluginInfo => with_plugin_info,
                        :withAttempts => with_attempts,
                        :audit => audit
                      },
                      options
        end
      end

      def commit(user = nil, reason = nil, comment = nil, options = {})

        self.class.put "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}/commitInvoice",
                       nil,
                       {},
                       {
                           :user => user,
                           :reason => reason,
                           :comment => comment,
                       }.merge(options)

      end

      def void(user = nil, reason = nil, comment = nil, options = {})

        self.class.put "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}/voidInvoice",
                       nil,
                       {},
                       {
                           :user => user,
                           :reason => reason,
                           :comment => comment,
                       }.merge(options)

      end

      def payments(with_plugin_info = false, with_attempts = false, audit = 'NONE', options = {})
        self.class.get "#{KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}/payments",
                       {
                           :withAttempts => with_attempts,
                           :withPluginInfo => with_plugin_info,
                           :audit          => audit
                       },
                       options,
                       InvoicePayment
      end

      def trigger_email_notifications(user = nil, reason = nil, comment = nil, options = {})
        self.class.post "#{KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}/emailNotifications",
                        {},
                        {},
                        {
                            :user    => user,
                            :reason  => reason,
                            :comment => comment,
                        }.merge(options)
      end
      private

      def self.nothing_to_generate?(invoice)
        return true if invoice.nil? || invoice.response.nil?
        invoice.response.code.to_i == 204
      end
    end
  end
end
