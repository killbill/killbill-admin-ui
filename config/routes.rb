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
  get '/500', to: 'errors#show', code: 500

  scope '/accounts' do
    get '/pagination' => 'accounts#pagination', :as => 'accounts_pagination'
    get '/validate_external_key' => 'accounts#validate_external_key', :as => 'accounts_validate_external_key'
    get '/download' => 'accounts#download', :as => 'download_accounts'
    get '/export/:account_id', to: 'accounts#export_account', as: 'export_account'

    scope '/email_notifications' do
      post '/' => 'accounts#set_email_notifications_configuration', :as => 'email_notifications_configuration'
      get '/events_to_consider' => 'accounts#events_to_consider', :as => 'email_notification_events_to_consider'
    end

    scope '/:account_id' do
      get '/next_invoice_date' => 'accounts#next_invoice_date', :as => 'next_invoice_date'
      post '/trigger_invoice' => 'accounts#trigger_invoice', :as => 'trigger_invoice'
      put '/link_to_parent' => 'accounts#link_to_parent', :as => 'link_to_parent'
      delete '/unlink_to_parent' => 'accounts#unlink_to_parent', :as => 'unlink_to_parent'

      scope '/account_tags' do
        get '/' => 'account_tags#index', :as => 'account_tags'
        get '/edit' => 'account_tags#edit', :as => 'edit_account_tags'
        post '/edit' => 'account_tags#update', :as => 'update_account_tags'
      end
      scope '/bundle_tags' do
        get '/edit' => 'bundle_tags#edit', :as => 'edit_bundle_tags'
        post '/edit' => 'bundle_tags#update', :as => 'update_bundle_tags'
      end
      scope '/invoice_tags' do
        get '/edit' => 'invoice_tags#edit', :as => 'edit_invoice_tags'
        post '/edit' => 'invoice_tags#update', :as => 'update_invoice_tags'
      end
      scope '/timeline' do
        get '/' => 'account_timelines#show', :as => 'account_timeline'
        get '/download' => 'account_timelines#download', :as => 'download_account_timeline'
      end
      scope '/custom_fields' do
        get '/' => 'account_custom_fields#index', :as => 'account_custom_fields'
      end
      scope '/account_children' do
        get '/' => 'account_children#index', :as => 'account_children'
        get '/pagination' => 'account_children#pagination', :as => 'account_children_pagination'
      end
      scope '/audit_logs' do
        get '/history' => 'audit_logs#history', :as => 'audit_logs_history'
        get '/download' => 'audit_logs#download', :as => 'download_audit_logs'
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
    get '/validate_external_key' => 'payment_methods#validate_external_key', :as => 'payment_methods_validate_external_key'
    post '/refresh' => 'payment_methods#refresh', :as => 'refresh_payment_methods'
  end
  resources :payment_methods, only: %i[new create show destroy]

  scope '/invoices' do
    get '/pagination' => 'invoices#pagination', :as => 'invoices_pagination'
    get '/download' => 'invoices#download', :as => 'download_invoices'
    get '/:id/show_html' => 'invoices#show_html', :as => 'show_html_invoice'
    get '/:number' => 'invoices#restful_show_by_number', :constraints => { number: /\d+/ }
    get '/:id' => 'invoices#restful_show', :as => 'invoice'
    post '/commit' => 'invoices#commit_invoice', :as => 'commit_invoice'
    delete '/void' => 'invoices#void_invoice', :as => 'void_invoice'
  end
  resources :invoices, only: [:index]

  scope '/invoice_items' do
    post '/:id/tags' => 'invoice_items#update_tags', :as => 'update_invoice_items_tags'
  end
  resources :invoice_items, only: %i[update destroy]

  scope '/payments' do
    get '/pagination' => 'payments#pagination', :as => 'payments_pagination'
    get '/download' => 'payments#download', :as => 'download_payments'
    get '/:id' => 'payments#restful_show', :as => 'payment'
    delete '/:id/cancel_scheduled_payment' => 'payments#cancel_scheduled_payment', :as => 'payment_cancel_scheduled_payment'
  end
  resources :payments, only: [:index]

  scope '/transactions' do
    get '/:id' => 'transactions#restful_show', :as => 'transaction'
    put '/fix_transaction_state' => 'transactions#fix_transaction_state', :as => 'fix_transaction_state'
  end

  scope '/bundles' do
    put '/:id/do_pause_resume', to: 'bundles#do_pause_resume', as: 'do_pause_resume_bundle'
    get '/:id/pause_resume', to: 'bundles#pause_resume', as: 'pause_resume_bundle'
    put '/:id/do_transfer', to: 'bundles#do_transfer', as: 'do_transfer_bundle'
    get '/:id/transfer', to: 'bundles#transfer', as: 'transfer_bundle'
    get '/:id' => 'bundles#restful_show', :as => 'bundle'
  end

  scope '/subscriptions' do
    post '/:id/tags' => 'subscriptions#update_tags', :as => 'update_subscriptions_tags'
    get '/:id/edit_bcd' => 'subscriptions#edit_bcd', :as => 'edit_bcd'
    put '/:id/update_bcd' => 'subscriptions#update_bcd', :as => 'update_bcd'
    put '/:id/reinstate' => 'subscriptions#reinstate', :as => 'reinstate'
    get '/validate_external_key' => 'subscriptions#validate_external_key', :as => 'subscriptions_validate_external_key'
    get '/validate_bundle_external_key' => 'subscriptions#validate_bundle_external_key', :as => 'subscriptions_validate_bundle_external_key'
  end
  resources :subscriptions, only: %i[new create show edit update destroy]

  scope '/tags' do
    get '/pagination' => 'tags#pagination', :as => 'tags_pagination'
  end
  resources :tags, only: [:index]

  resources :tag_definitions, only: %i[index new create destroy]

  scope '/custom_fields' do
    get '/pagination' => 'custom_fields#pagination', :as => 'custom_fields_pagination'
    get '/check_object_exist' => 'custom_fields#check_object_exist', :as => 'custom_fields_check_object_exist'
  end
  resources :custom_fields, only: %i[index new create check_object_exist]

  scope '/tenants' do
    get '/' => 'tenants#index', :as => 'tenants'
    post '/select_tenant' => 'tenants#select_tenant', :as => 'select_tenant'
  end

  scope '/login_proxy' do
    get '/check_login' => 'login_proxy#check_login', :as => 'check_login'
  end

  scope '/home' do
    get '/' => 'home#index', :as => 'home'
    get '/search' => 'home#search', :as => 'search'
  end

  scope '/queues' do
    get '/' => 'queues#index', :as => 'queues'
  end

  scope '/admin' do
    get '/' => 'admin#index', :as => 'admin'
    put '/clock' => 'admin#set_clock', :as => 'admin_set_clock'
  end

  scope '/admin_tenants' do
    put '/:id/clock' => 'admin_tenants#set_clock', :as => 'admin_tenant_set_clock'
    get '/:id/new_catalog' => 'admin_tenants#new_catalog', :as => 'admin_tenant_new_catalog'
    delete '/:id/delete_catalog' => 'admin_tenants#delete_catalog', :as => 'admin_tenant_delete_catalog'
    get '/:id/new_plan_currency' => 'admin_tenants#new_plan_currency', :as => 'admin_tenant_new_plan_currency'
    get '/:id/new_overdue_config' => 'admin_tenants#new_overdue_config', :as => 'admin_tenant_new_overdue_config'
    post '/upload_catalog' => 'admin_tenants#upload_catalog', :as => 'admin_tenant_upload_catalog'
    post '/display_catalog_xml' => 'admin_tenants#display_catalog_xml', :as => 'admin_tenant_display_catalog_xml'
    post '/display_overdue_xml' => 'admin_tenants#display_overdue_xml', :as => 'admin_tenant_display_overdue_xml'
    post '/create_simple_plan' => 'admin_tenants#create_simple_plan', :as => 'admin_tenant_create_simple_plan'
    post '/modify_overdue_config' => 'admin_tenants#modify_overdue_config', :as => 'admin_tenant_modify_overdue_config'
    post '/upload_overdue_config' => 'admin_tenants#upload_overdue_config', :as => 'admin_tenant_upload_overdue_config'
    post '/upload_invoice_template' => 'admin_tenants#upload_invoice_template', :as => 'admin_tenant_upload_invoice_template'
    post '/upload_invoice_translation' => 'admin_tenants#upload_invoice_translation', :as => 'admin_tenant_upload_invoice_translation'
    post '/upload_catalog_translation' => 'admin_tenants#upload_catalog_translation', :as => 'admin_tenant_upload_catalog_translation'
    post '/upload_plugin_config' => 'admin_tenants#upload_plugin_config', :as => 'admin_tenant_upload_plugin_config'
    delete '/remove_allowed_user' => 'admin_tenants#remove_allowed_user', :as => 'remove_allowed_user'
    put '/add_allowed_user' => 'admin_tenants#add_allowed_user', :as => 'add_allowed_user'
    get '/allowed_users' => 'admin_tenants#allowed_users', :as => 'admin_tenant_allowed_users'
    get '/catalog_by_effective_date' => 'admin_tenants#catalog_by_effective_date', :as => 'catalog_by_effective_date'
    get '/switch' => 'admin_tenants#switch_tenant', :as => 'switch_tenant'
    get '/:id/download_catalog' => 'admin_tenants#download_catalog_xml', :as => 'download_catalog_xml'
  end
  resources :admin_tenants, only: %i[index new create show]

  resources :admin_allowed_users
  scope '/admin_allowed_users' do
    post '/add_tenant' => 'admin_allowed_users#add_tenant', :as => 'add_tenant'
  end

  resources :role_definitions, only: %i[new create]
end
