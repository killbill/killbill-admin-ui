Kaui::Engine.routes.draw do
  root :to => "home#index"

  resources :accounts, :only => [ :index, :show ] do
  	member do
	    get :payment_methods, :as => "payment_methods"
	    put :set_default_payment_method, :as => "set_default_payment_method"
	    delete :delete_payment_method, :as => "delete_payment_method"
		end
  end

  resources :account_timelines, :only => [ :index, :show ] do
    member do
      post :refunds, :as => "refunds"
      post :chargebacks, :as => "chargebacks"
      post :credits, :as => "credits"
    end
  end

  resources :chargebacks, :only => [ :show, :create, :new ]

  resources :credits, :only => [ :create, :new ]

  resources :external_payments, :only => [ :create, :new ]

  resources :payment_methods, :only => [ :show, :destroy ]

  resources :refunds, :only => [ :show, :create, :new ]

  resources :invoices, :only => [ :index, :show ] do
    member do
      get :show_html
    end
  end

  resources :bundles, :only => [ :index, :show ]

  resources :subscriptions do
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

end
