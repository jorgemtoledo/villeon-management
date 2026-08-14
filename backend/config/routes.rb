Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Only :sessions routes — no registrations/passwords/confirmations/unlocks yet.
  # path_names remaps them to POST /api/v1/login and DELETE /api/v1/logout,
  # matching config.jwt.dispatch_requests/revocation_requests in devise.rb.
  devise_for :users,
    path: "api/v1",
    path_names: { sign_in: "login", sign_out: "logout" },
    controllers: { sessions: "api/v1/sessions" },
    skip: %i[registrations passwords confirmations unlocks]

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      get "me", to: "me#show"

      resources :products, only: %i[index show create update] do
        member do
          patch :activate
          patch :deactivate
        end

        resource :stock, only: %i[show update], controller: "product_stocks" do
          patch :priority, to: "product_stocks#update_priority"
        end
        resources :stock_counts, only: %i[create], controller: "stock_counts"
        resources :stock_audit_entries, only: %i[index], controller: "stock_audit_entries"
        resources :suppliers, only: %i[index create destroy], controller: "product_suppliers" do
          member do
            patch :prefer
          end
        end
      end

      resources :product_stocks, only: %i[index], controller: "product_stocks"
      resources :stock_counts, only: %i[update], controller: "stock_counts"
      resources :stock_audit_entries, only: %i[index], controller: "stock_audit_entries" do
        collection do
          get :users
        end
      end

      resources :suppliers, only: %i[index show create update] do
        member do
          patch :activate
          patch :deactivate
          get :products
        end
      end

      resources :units, only: %i[index]
      resources :subcategories, only: %i[index]

      resources :purchases, only: %i[index show create update]

      resources :users, only: %i[index show create update] do
        member do
          patch :activate
          patch :deactivate
        end
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
