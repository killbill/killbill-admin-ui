Kaui::Engine.routes.draw do
  devise_for :users, :class_name => 'Kaui::User', :module => :devise

  resources :tag_definitions

  root :to => "home#index"

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

  resources :chargebacks, :only => [ :show, :create, :new ]

  resources :credits, :only => [ :create, :new ]

  resources :charges, :only => [ :create, :new ]

  resources :external_payments, :only => [ :create, :new ]

  resources :payments, :only => [ :create, :new, :index, :show ]

  resources :payment_methods, :only => [ :index, :show, :destroy ]

  resources :refunds, :only => [ :index, :show, :create, :new ]

  resources :invoices, :only => [ :index, :show ] do
    member do
      get :show_html
    end
  end

  resources :invoice_items, :only => [ :index, :show, :edit, :update, :destroy ]

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

end
