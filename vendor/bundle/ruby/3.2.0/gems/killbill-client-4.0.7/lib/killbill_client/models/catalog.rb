module KillBillClient
  module Model
    class Catalog < CatalogAttributes

      has_many :products, KillBillClient::Model::Product

      KILLBILL_API_CATALOG_PREFIX = "#{KILLBILL_API_PREFIX}/catalog"

      class << self
        def simple_catalog(account_id = nil, options = {})
          get "#{KILLBILL_API_CATALOG_PREFIX}",
              {
                :accountId => account_id
              },
              options
        end

        def available_addons(base_product_name, account_id = nil, options = {})
          get "#{KILLBILL_API_CATALOG_PREFIX}/availableAddons",
              {
                  :baseProductName => base_product_name,
                  :accountId => account_id
              },
              options,
              PlanDetail
        end

        def available_base_plans(account_id = nil, options = {})
          get "#{KILLBILL_API_CATALOG_PREFIX}/availableBasePlans",
              {
                :accountId => account_id
              },
              options,
              PlanDetail
        end

        def get_tenant_catalog_versions(account_id = nil, options = {})

          require_multi_tenant_options!(options, "Retrieving catalog versions is only supported in multi-tenant mode")

          get "#{KILLBILL_API_CATALOG_PREFIX}/versions",
              {
                :accountId => account_id
              },
              options
        end

        def get_tenant_catalog_xml(requested_date = nil, account_id = nil, options = {})

          require_multi_tenant_options!(options, "Retrieving a catalog is only supported in multi-tenant mode")

          params = {}
          params[:requestedDate] = requested_date if requested_date
          params[:account_id] = account_id if account_id

          get "#{KILLBILL_API_CATALOG_PREFIX}/xml",
              params,
              {
                  :head => {'Accept' => "text/xml"},
                  :content_type => "text/xml",

          }.merge(options)

        end

        def get_tenant_catalog_json(requested_date = nil, account_id = nil, options = {})

          require_multi_tenant_options!(options, "Retrieving a catalog is only supported in multi-tenant mode")

          params = {}
          params[:requestedDate] = requested_date if requested_date
          params[:account_id] = account_id if account_id

          get KILLBILL_API_CATALOG_PREFIX,
              params,
              {
                  :head => {'Accept' => "application/json"},
                  :content_type => "application/json",

              }.merge(options)

        end

        def get_catalog_phase(subscription_id, requested_date, options = {})

          require_multi_tenant_options!(options, "Retrieving catalog phase is only supported in multi-tenant mode")

          params = {}
          params[:subscriptionId] = subscription_id if subscription_id
          params[:requestedDate] = requested_date if requested_date

          get "#{KILLBILL_API_CATALOG_PREFIX}/phase",
              params,
              options
        end

        def get_catalog_plan(subscription_id, requested_date, options = {})

          require_multi_tenant_options!(options, "Retrieving catalog plan is only supported in multi-tenant mode")

          params = {}
          params[:subscriptionId] = subscription_id if subscription_id
          params[:requestedDate] = requested_date if requested_date

          get "#{KILLBILL_API_CATALOG_PREFIX}/plan",
              params,
              options
        end

        def get_catalog_price_list(subscription_id, requested_date, options = {})

          require_multi_tenant_options!(options, "Retrieving catalog price list is only supported in multi-tenant mode")

          params = {}
          params[:subscriptionId] = subscription_id if subscription_id
          params[:requestedDate] = requested_date if requested_date

          get "#{KILLBILL_API_CATALOG_PREFIX}/priceList",
              params,
              options
        end

        def get_catalog_product(subscription_id, requested_date, options = {})

          require_multi_tenant_options!(options, "Retrieving catalog product list is only supported in multi-tenant mode")

          params = {}
          params[:subscriptionId] = subscription_id if subscription_id
          params[:requestedDate] = requested_date if requested_date

          get "#{KILLBILL_API_CATALOG_PREFIX}/product",
              params,
              options
        end

        def upload_tenant_catalog(catalog_xml, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading a catalog is only supported in multi-tenant mode")

          post "#{KILLBILL_API_CATALOG_PREFIX}/xml",
               catalog_xml,
               {
               },
               {
                   :head => {'Accept' => 'application/json'},
                   :content_type => 'text/xml',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
          get_tenant_catalog_json(nil, nil, options)
        end


        def add_tenant_catalog_simple_plan(simple_plan, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading a catalog is only supported in multi-tenant mode")

          post "#{KILLBILL_API_CATALOG_PREFIX}/simplePlan",
               simple_plan.to_json,
               {
               },
               {
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
        end

        def delete_catalog(user = nil, reason = nil, comment = nil, options = {})

          delete "#{KILLBILL_API_CATALOG_PREFIX}",
                 {},
                 {},
                 {
                     :user => user,
                     :reason => reason,
                     :comment => comment,
                 }.merge(options)
        end

        def validate_catalog(catalog_xml, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Validating a catalog is only supported in multi-tenant mode")

          errors = post "#{KILLBILL_API_CATALOG_PREFIX}/xml/validate",
               catalog_xml,
               {},
               {
                   :head => {'Accept' => 'application/json'},
                   :content_type => 'text/xml',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
        end
      end
    end
  end
end
