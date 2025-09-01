Rails.application.routes.draw do
  # Authentication
  post '/login', to: 'sessions#create'
  post '/signup', to: 'users#create'

  # Core resources
  resources :categories
  resources :expenses
  resources :incomes

  # Monthly reviews
  resources :monthly_reviews, only: [:index, :show, :create, :update] do
    collection do
      get 'by_month_code/:month_code', to: 'monthly_reviews#by_month_code'
    end
    member do
      post :rebuild
      patch :toggle_complete
    end
  end

  resources :monthly_category_reviews, only: [:update, :show] 

end
