Rails.application.routes.draw do
  post '/login', to: 'sessions#create'
  post '/signup', to: 'users#create'

  resources :users, only: [:show, :update]

  resources :categories
  resources :expenses
  resources :incomes

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
