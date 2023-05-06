# frozen_string_literal: true

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
             class_name: 'Kaui::User',
             module: :devise,
             controllers: { sessions: 'kaui/sessions', registrations: 'kaui/registrations' }

  root to: 'home#index', as: 'kaui'

  scope '/accounts' do
    match '/pagination' => 'accounts#pagination', :via => :get, :as => 'accounts_pagination'
    match '/validate_external_key' => 'accounts#validate_external_key', :via => :get, :as => 'accounts_validate_external_key'

    scope '/email_notifications' do
      match '/' => 'accounts#set_email_notifications_configuration', :via => :post, :as => 'email_notifications_configuration'
      match '/events_to_consider' => 'accounts#events_to_consider', :via => :get, :as => 'email_notification_events_to_consider'
    end

    scope '/:account_id' do
      match '/next_invoice_date' => 'accounts#next_invoice_date', :via => :get, :as => 'next_invoice_date'
      match '/trigger_invoice' => 'accounts#trigger_invoice', :via => :post, :as => 'trigger_invoice'
      match '/link_to_parent' => 'accounts#link_to_parent', :via => :put, :as => 'link_to_parent'
      match '/unlink_to_parent' => 'accounts#unlink_to_parent', :via => :delete, :as => 'unlink_to_parent'

      scope '/account_tags' do
        match '/' => 'account_tags#index', :via => :get, :as => 'account_tags'
        match '/edit' => 'account_tags#edit', :via => :get, :as => 'edit_account_tags'
        match '/edit' => 'account_tags#update', :via => :post, :as => 'update_account_tags'
      end
      scope '/bundle_tags' do
        match '/edit' => 'bundle_tags#edit', :via => :get, :as => 'edit_bundle_tags'
        match '/edit' => 'bundle_tags#update', :via => :post, :as => 'update_bundle_tags'
      end
      scope '/invoice_tags' do
        match '/edit' => 'invoice_tags#edit', :via => :get, :as => 'edit_invoice_tags'
        match '/edit' => 'invoice_tags#update', :via => :post, :as => 'update_invoice_tags'
      end
      scope '/timeline' do
        match '/' => 'account_timelines#show', :via => :get, :as => 'account_timeline'
      end
      scope '/custom_fields' do
        match '/' => 'account_custom_fields#index', :via => :get, :as => 'account_custom_fields'
      end
      scope '/account_children' do
        match '/' => 'account_children#index', :via => :get, :as => 'account_children'
        match '/pagination' => 'account_children#pagination', :via => :get, :as => 'account_children_pagination'
      end
      scope '/audit_logs' do
        match '/history' => 'audit_logs#history', :via => :get, :as => 'audit_logs_history'
      end
    end
  end
  resources :accounts, only: %i[index new create edit update show destroy], param: :account_id do
    member do
      put :set_default_payment_method
      delete :delete_payment_method
      post :toggle_email_notifications
      post :pay_all_invoices
    end

    # The id is the email itself
    resources :account_emails, only: %i[new create destroy], constraints: { id: /[\w+\-;@.]+/ }, path: 'emails'
    resources :bundles, only: [:index]
    resources :charges, only: %i[new create]
    resources :chargebacks, only: %i[new create]
    resources :credits, only: %i[new create]
    resources :invoices, only: %i[index show]
    resources :invoice_items, only: [:edit]
    resources :payments, only: %i[index show new create]
    resources :refunds, only: %i[new create]
    resources :transactions, only: %i[new create]
    resources :queues, only: [:index]
    resources :audit_logs, only: [:index]
  end

  scope '/payment_methods' do
    match '/validate_external_key' => 'payment_methods#validate_external_key', :via => :get, :as => 'payment_methods_validate_external_key'
    match '/refresh' => 'payment_methods#refresh', :via => :post, :as => 'refresh_payment_methods'
  end
  resources :payment_methods, only: %i[new create show destroy]

  scope '/invoices' do
    match '/pagination' => 'invoices#pagination', :via => :get, :as => 'invoices_pagination'
    match '/:id/show_html' => 'invoices#show_html', :via => :get, :as => 'show_html_invoice'
    match '/:id' => 'invoices#restful_show', :via => :get, :as => 'invoice'
    match '/commit' => 'invoices#commit_invoice', :via => :post, :as => 'commit_invoice'
    match '/void' => 'invoices#void_invoice', :via => :delete, :as => 'void_invoice'
  end
  resources :invoices, only: [:index]

  scope '/invoice_items' do
    match '/:id/tags' => 'invoice_items#update_tags', :via => :post, :as => 'update_invoice_items_tags'
  end
  resources :invoice_items, only: %i[update destroy]

  scope '/payments' do
    match '/pagination' => 'payments#pagination', :via => :get, :as => 'payments_pagination'
    match '/:id' => 'payments#restful_show', :via => :get, :as => 'payment'
    match '/:id/cancel_scheduled_payment' => 'payments#cancel_scheduled_payment', :via => :delete, :as => 'payment_cancel_scheduled_payment'
  end
  resources :payments, only: [:index]

  scope '/transactions' do
    match '/:id' => 'transactions#restful_show', :via => :get, :as => 'transaction'
    match '/fix_transaction_state' => 'transactions#fix_transaction_state', :via => :put, :as => 'fix_transaction_state'
  end

  scope '/bundles' do
    put '/:id/do_pause_resume', to: 'bundles#do_pause_resume', as: 'do_pause_resume_bundle'
    get '/:id/pause_resume', to: 'bundles#pause_resume', as: 'pause_resume_bundle'
    put '/:id/do_transfer', to: 'bundles#do_transfer', as: 'do_transfer_bundle'
    get '/:id/transfer', to: 'bundles#transfer', as: 'transfer_bundle'
    match '/:id' => 'bundles#restful_show', :via => :get, :as => 'bundle'
  end

  scope '/subscriptions' do
    match '/:id/tags' => 'subscriptions#update_tags', :via => :post, :as => 'update_subscriptions_tags'
    match '/:id/edit_bcd' => 'subscriptions#edit_bcd', :via => :get, :as => 'edit_bcd'
    match '/:id/update_bcd' => 'subscriptions#update_bcd', :via => :put, :as => 'update_bcd'
    match '/:id/reinstate' => 'subscriptions#reinstate', :via => :put, :as => 'reinstate'
    match '/validate_external_key' => 'subscriptions#validate_external_key', :via => :get, :as => 'subscriptions_validate_external_key'
    match '/validate_bundle_external_key' => 'subscriptions#validate_bundle_external_key', :via => :get, :as => 'subscriptions_validate_bundle_external_key'
  end
  resources :subscriptions, only: %i[new create show edit update destroy]

  scope '/tags' do
    match '/pagination' => 'tags#pagination', :via => :get, :as => 'tags_pagination'
  end
  resources :tags, only: [:index]

  resources :tag_definitions, only: %i[index new create destroy]

  scope '/custom_fields' do
    match '/pagination' => 'custom_fields#pagination', :via => :get, :as => 'custom_fields_pagination'
    match '/check_object_exist' => 'custom_fields#check_object_exist', :via => :get, :as => 'custom_fields_check_object_exist'
  end
  resources :custom_fields, only: %i[index new create check_object_exist]

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

  scope '/queues' do
    match '/' => 'queues#index', :via => :get, :as => 'queues'
  end

  scope '/admin' do
    match '/' => 'admin#index', :via => :get, :as => 'admin'
    match '/clock' => 'admin#set_clock', :via => :put, :as => 'admin_set_clock'
  end

  scope '/admin_tenants' do
    match '/:id/new_catalog' => 'admin_tenants#new_catalog', :via => :get, :as => 'admin_tenant_new_catalog'
    match '/:id/delete_catalog' => 'admin_tenants#delete_catalog', :via => :delete, :as => 'admin_tenant_delete_catalog'
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
    match '/add_allowed_user' => 'admin_tenants#add_allowed_user', :via => :put, :as => 'add_allowed_user'
    match '/allowed_users' => 'admin_tenants#allowed_users', :via => :get, :as => 'admin_tenant_allowed_users'
    match '/catalog_by_effective_date' => 'admin_tenants#catalog_by_effective_date', :via => :get, :as => 'catalog_by_effective_date'
    match '/switch' => 'admin_tenants#switch_tenant', :via => :get, :as => 'switch_tenant'
    match '/:id/download_catalog' => 'admin_tenants#download_catalog_xml', :via => :get, :as => 'download_catalog_xml'
  end
  resources :admin_tenants, only: %i[index new create show]

  resources :admin_allowed_users
  scope '/admin_allowed_users' do
    match '/add_tenant' => 'admin_allowed_users#add_tenant', :via => :post, :as => 'add_tenant'
  end

  resources :role_definitions, only: %i[new create]
end
