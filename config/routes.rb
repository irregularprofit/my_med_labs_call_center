MyMedLabsCallCenter::Application.routes.draw do

  devise_for :users

  namespace :admin do
    resources :users
  end
  root to: "home#index"
  resources :connects, only: :index do
    post :voice, on: :collection
  end
end
