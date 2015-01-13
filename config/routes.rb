Kaui::Engine.routes.draw do

  devise_for :users,
             :class_name => 'Kaui::User',
             :module => :devise,
             :controllers => { :sessions => 'kaui/sessions'}

  resources :tag_definitions

  # STEPH_TENANT We 'd like to keep home#index as the root and have Devise redirect to "tenants#index" when configured in multi-tenant mode.
  root :to => "home#index"
  #root :to => "tenants#index"

  scope "/accounts" do
    match "/pagination" => "accounts#pagination", :via => :get, :as => "accounts_pagination"
  end
  resources :accounts, :only => [ :index, :show ] do
    member do
      get :payment_methods
      put :set_default_payment_method
      get :add_payment_method
      post :do_add_payment_method
      delete :delete_payment_method
      post :toggle_email_notifications
      post :pay_all_invoices
    end
  end

  resources :account_emails, :only => [ :create, :new, :show, :destroy ]

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

  scope "/payment_methods" do
    match "/pagination" => "payment_methods#pagination", :via => :get, :as => "payment_methods_pagination"
  end
  resources :payment_methods, :only => [ :index, :show, :destroy ]

  scope "/refunds" do
    match "/pagination" => "refunds#pagination", :via => :get, :as => "refunds_pagination"
  end
  resources :refunds, :only => [ :index, :show, :create, :new ]

  scope "/invoices" do
    match "/pagination" => "invoices#pagination", :via => :get, :as => "invoices_pagination"
  end
  resources :invoices, :only => [ :index, :show ] do
    member do
      get :show_html
    end
  end

  resources :invoice_items, :only => [ :index, :show, :edit, :update, :destroy ]

  scope "/bundles" do
    match "/pagination" => "bundles#pagination", :via => :get, :as => "bundles_pagination"
  end
  resources :bundles, :only => [ :index, :show ] do
    member do
      put :do_transfer
      get :transfer
    end
  end

  resources :subscriptions do
    member do
      put :reinstate
    end
  end

  scope "/analytics" do
    match "/" => "analytics#index", :via => :get, :as => "analytics"
    match "/account_snapshot" => "analytics#account_snapshot", :via => :get, :as => "account_snapshot"
    match "/refresh_account" => "analytics#refresh_account", :via => :post, :as => "refresh_account"
    match "/accounts_over_time" => "analytics#accounts_over_time", :via => :get, :as => "analytics_accounts_over_time"
    match "/subscriptions_over_time" => "analytics#subscriptions_over_time", :via => :get, :as => "analytics_subscriptions_over_time"
    match "/sanity" => "analytics#sanity", :via => :get, :as => "analytics_sanity"
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

  scope "/home" do
    match "/" => "home#index", :via => :get, :as => "home"
  end


  resources :custom_fields, :only => [ :create, :new, :index, :show ]
end
