module ActionDispatch
  module Routing
    class Mapper
      module Resources
        class Resource
          def nested_param
            # Fix an issue where nested param would be account_account_id
            param.to_s.start_with?(singular) ? param : super
          end
        end
      end
    end
  end
end

Kaui::Engine.routes.draw do

  devise_for :users,
             :class_name => 'Kaui::User',
             :module => :devise,
             :controllers => { :sessions => 'kaui/sessions', :registrations => 'kaui/registrations' }

  root :to => 'home#index', as: 'kaui'

  scope '/accounts' do
    match '/pagination' => 'accounts#pagination', :via => :get, :as => 'accounts_pagination'

    scope '/:account_id' do
      match '/next_invoice_date' => 'accounts#next_invoice_date', :via => :get, :as => 'next_invoice_date'

      scope '/account_tags' do
        match '/edit' => 'account_tags#edit', :via => :get, :as => 'edit_account_tags'
        match '/edit' => 'account_tags#update', :via => :post, :as => 'update_account_tags'
      end
      scope '/bundle_tags' do
        match '/edit' => 'bundle_tags#edit', :via => :get, :as => 'edit_bundle_tags'
        match '/edit' => 'bundle_tags#update', :via => :post, :as => 'update_bundle_tags'
      end
      scope '/timeline' do
        match '/' => 'account_timelines#show', :via => :get, :as => 'account_timeline'
      end
    end
  end
  resources :accounts, :only => [ :index, :new, :create, :edit, :update, :show ], :param => :account_id do
    member do
      put :set_default_payment_method
      delete :delete_payment_method
      post :toggle_email_notifications
      post :pay_all_invoices
    end

    # The id is the email itself
    resources :account_emails, :only => [:new, :create, :destroy], :constraints => { :id => /[\w+\-;@\.]+/ }, :path => 'emails'
    resources :bundles, :only => [:index]
    resources :charges, :only => [:new, :create]
    resources :chargebacks, :only => [:new, :create]
    resources :credits, :only => [:new, :create]
    resources :invoices, :only => [:index, :show]
    resources :invoice_items, :only => [:edit]
    resources :payments, :only => [:index, :show, :new, :create]
    resources :refunds, :only => [:new, :create]
    resources :transactions, :only => [:new, :create]
  end

  resources :payment_methods, :only => [:new, :create, :show, :destroy]

  scope '/invoices' do
    match '/pagination' => 'invoices#pagination', :via => :get, :as => 'invoices_pagination'
    match '/:id/show_html' => 'invoices#show_html', :via => :get, :as => 'show_html_invoice'
    match '/:id' => 'invoices#restful_show', :via => :get, :as => 'invoice'
  end
  resources :invoices, :only => [ :index ]

  resources :invoice_items, :only => [:update, :destroy]

  scope '/payments' do
    match '/pagination' => 'payments#pagination', :via => :get, :as => 'payments_pagination'
    match '/:id' => 'payments#restful_show', :via => :get, :as => 'payment'
    match '/:id/cancel_scheduled_payment' => 'payments#cancel_scheduled_payment', :via => :delete, :as => 'payment_cancel_scheduled_payment'
  end
  resources :payments, :only => [ :index ]

  scope '/transactions' do
    match '/:id' => 'transactions#restful_show', :via => :get, :as => 'transaction'
  end

  scope '/bundles' do
    put '/:id/do_transfer', :to => 'bundles#do_transfer', :as => 'do_transfer_bundle'
    get '/:id/transfer', :to => 'bundles#transfer', :as => 'transfer_bundle'
    match '/:id' => 'bundles#restful_show', :via => :get, :as => 'bundle'
  end

  resources :subscriptions, :only => [:new, :create, :show, :edit, :update, :destroy] do
    member do
      put :reinstate
    end
  end

  scope '/tags' do
    match '/pagination' => 'tags#pagination', :via => :get, :as => 'tags_pagination'
  end
  resources :tags, :only => [:index]

  resources :tag_definitions, :only => [:index, :new, :create, :destroy]

  scope '/custom_fields' do
    match '/pagination' => 'custom_fields#pagination', :via => :get, :as => 'custom_fields_pagination'
  end
  resources :custom_fields, :only => [:index, :new, :create]

  scope '/tenants' do
    match '/' => 'tenants#index', :via => :get, :as => 'tenants'
    match '/select_tenant' => 'tenants#select_tenant', :via => :post, :as => 'select_tenant'
  end

  scope '/login_proxy' do
    match '/check_login' => 'login_proxy#check_login', :via => :get, :as => 'check_login'
  end

  scope '/home' do
    match '/' => 'home#index', :via => :get, :as => 'home'
    match '/search' => 'home#search', :via => :get, :as => 'search'
  end

  resources :admin_tenants, :only => [ :index, :new, :create, :show ]
  scope '/admin_tenants' do
    match '/:id/new_catalog' => 'admin_tenants#new_catalog', :via => :get, :as => 'admin_tenant_new_catalog'
    match '/:id/new_plan_currency' => 'admin_tenants#new_plan_currency', :via => :get, :as => 'admin_tenant_new_plan_currency'
    match '/:id/new_overdue_config' => 'admin_tenants#new_overdue_config', :via => :get, :as => 'admin_tenant_new_overdue_config'
    match '/upload_catalog' => 'admin_tenants#upload_catalog', :via => :post, :as => 'admin_tenant_upload_catalog'
    match '/display_catalog_xml' => 'admin_tenants#display_catalog_xml', :via => :post, :as => 'admin_tenant_display_catalog_xml'
    match '/display_overdue_xml' => 'admin_tenants#display_overdue_xml', :via => :post, :as => 'admin_tenant_display_overdue_xml'
    match '/create_simple_plan' => 'admin_tenants#create_simple_plan', :via => :post, :as => 'admin_tenant_create_simple_plan'
    match '/modify_overdue_config' => 'admin_tenants#modify_overdue_config', :via => :post, :as => 'admin_tenant_modify_overdue_config'
    match '/upload_overdue_config' => 'admin_tenants#upload_overdue_config', :via => :post, :as => 'admin_tenant_upload_overdue_config'
    match '/upload_invoice_template' => 'admin_tenants#upload_invoice_template', :via => :post, :as => 'admin_tenant_upload_invoice_template'
    match '/upload_invoice_translation' => 'admin_tenants#upload_invoice_translation', :via => :post, :as => 'admin_tenant_upload_invoice_translation'
    match '/upload_catalog_translation' => 'admin_tenants#upload_catalog_translation', :via => :post, :as => 'admin_tenant_upload_catalog_translation'
    match '/upload_plugin_config' => 'admin_tenants#upload_plugin_config', :via => :post, :as => 'admin_tenant_upload_plugin_config'
    match '/remove_allowed_user' => 'admin_tenants#remove_allowed_user', :via => :delete, :as => 'remove_allowed_user'
  end

  resources :admin_allowed_users, :only => [ :index, :new, :create, :show ]
  scope '/admin_allowed_users' do
    match '/add_tenant' => 'admin_allowed_users#add_tenant', :via => :post, :as => 'add_tenant'
  end
end
