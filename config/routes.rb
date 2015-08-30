Kaui::Engine.routes.draw do

  devise_for :users,
             :class_name => 'Kaui::User',
             :module => :devise,
             :controllers => { :sessions => 'kaui/sessions'}

  resources :tag_definitions

  root :to => "home#index", as: 'kaui'

  scope "/accounts" do
    match "/pagination" => "accounts#pagination", :via => :get, :as => "accounts_pagination"
  end
  resources :accounts, :only => [ :index, :new, :create, :show ] do
    member do
      put :set_default_payment_method
      delete :delete_payment_method
      post :toggle_email_notifications
      post :pay_all_invoices
    end

    resources :bundles, :only => [:index]
    resources :invoices, :only => [:index]
  end

  scope '/account_emails' do
    match '/' => 'account_emails#destroy', :via => :delete, :as => 'account_email'
  end
  resources :account_emails, :only => [:new, :create]

  resources :account_timelines, :only => [ :index, :show ] do
    member do
      post :refunds, :as => "refunds"
      post :chargebacks, :as => "chargebacks"
      post :credits, :as => "credits"
      post :payments, :as => "payments"
      post :charges, :as => "charges"
    end
  end

  resources :chargebacks, :only => [ :create, :new ]

  resources :credits, :only => [ :create, :new ]

  resources :charges, :only => [ :create, :new ]

  resources :external_payments, :only => [ :create, :new ]

  scope "/payments" do
    match "/pagination" => "payments#pagination", :via => :get, :as => "payments_pagination"
  end
  resources :payments, :only => [ :create, :new, :index, :show ]
  resources :transactions, :only => [ :create, :new ]

  resources :payment_methods, :only => [ :new, :create, :destroy ]

  scope "/refunds" do
    match "/pagination" => "refunds#pagination", :via => :get, :as => "refunds_pagination"
  end
  resources :refunds, :only => [ :index, :show, :create, :new ]

  scope "/invoices" do
    match "/pagination" => "invoices#pagination", :via => :get, :as => "invoices_pagination"
  end
  resources :invoices, :only => [ :show ] do
    member do
      get :show_html
    end
  end

  resources :invoice_items, :only => [ :index, :show, :edit, :update, :destroy ]

  scope '/bundles' do
    put '/:id/do_transfer', :to => 'bundles#do_transfer', :as => 'do_transfer_bundle'
    get '/:id/transfer', :to => 'bundles#transfer', :as => 'transfer_bundle'
  end

  resources :subscriptions, :only => [:new, :create, :edit, :update, :destroy] do
    member do
      put :reinstate
    end
  end

  scope "/account_tags" do
    match "/" => "account_tags#show", :via => :get, :as => "account_tags"
    match "/edit" => "account_tags#edit", :via => :get, :as => "edit_account_tags"
    match "/edit" => "account_tags#update", :via => :post, :as => "update_account_tags"
  end

  scope "/bundle_tags" do
    match "/" => "bundle_tags#show", :via => :get, :as => "bundle_tags"
    match "/edit" => "bundle_tags#edit", :via => :get, :as => "edit_bundle_tags"
    match "/edit" => "bundle_tags#update", :via => :post, :as => "update_bundle_tags"
  end

  scope "/tags" do
    match "/pagination" => "tags#pagination", :via => :get, :as => "tags_pagination"
  end
  resources :tags, :only => [ :create, :new, :index, :show ]

  scope "/custom_fields" do
    match "/pagination" => "custom_fields#pagination", :via => :get, :as => "custom_fields_pagination"
  end

  scope "/tenants" do
    match "/" => "tenants#index", :via => :get, :as => "tenants"
    match "/select_tenant" => "tenants#select_tenant", :via => :post, :as => "select_tenant"
  end

  scope "/login_proxy" do
    match "/check_login" => "login_proxy#check_login", :via => :get, :as => "check_login"
  end

  scope "/home" do
    match "/" => "home#index", :via => :get, :as => "home"
    match "/search" => "home#search", :via => :get, :as => "search"
  end

  resources :admin_tenants, :only => [ :index, :new, :create, :show ]
  scope "/admin_tenants" do
    match "/upload_catalog" => "admin_tenants#upload_catalog", :via => :post, :as => "admin_tenant_upload_catalog"
    match "/upload_overdue_config" => "admin_tenants#upload_overdue_config", :via => :post, :as => "admin_tenant_upload_overdue_config"
    match "/upload_invoice_template" => "admin_tenants#upload_invoice_template", :via => :post, :as => "admin_tenant_upload_invoice_template"
    match "/upload_invoice_translation" => "admin_tenants#upload_invoice_translation", :via => :post, :as => "admin_tenant_upload_invoice_translation"
    match "/upload_catalog_translation" => "admin_tenants#upload_catalog_translation", :via => :post, :as => "admin_tenant_upload_catalog_translation"
    match "/upload_plugin_config" => "admin_tenants#upload_plugin_config", :via => :post, :as => "admin_tenant_upload_plugin_config"
    match "/remove_allowed_user" => "admin_tenants#remove_allowed_user", :via => :delete, :as => "remove_allowed_user"
  end

  resources :admin_allowed_users, :only => [ :index, :new, :create, :show ]
  scope "/admin_allowed_users" do
    match "/add_tenant" => "admin_allowed_users#add_tenant", :via => :post, :as => "add_tenant"
  end

  resources :custom_fields, :only => [ :create, :new, :index, :show ]
end
