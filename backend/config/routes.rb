Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  devise_for :users, path: "api/v1/auth", controllers: {
    sessions: "api/v1/users/sessions",
    registrations: "api/v1/users/registrations"
  }

  namespace :api do
    namespace :v1 do
      resources :tournaments, only: [ :index, :show, :create ] do
        resources :categories, only: [ :create ]
      end
      resources :categories, only: [] do
        resources :shiajos, only: [ :create ]
      end
      resources :matches, only: [ :show ] do
        resources :match_events, only: [ :create ]
      end
      resources :shiajos, only: [] do
        member do
          get :projector
          get :summary
        end
      end
      resources :category_types, only: [ :index, :create ]
      resources :seasons, only: [ :index, :create ]
      resources :disciplines, only: [ :index ]
    end
  end
end
