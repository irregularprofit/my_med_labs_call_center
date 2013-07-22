MyMedLabsCallCenter::Application.routes.draw do

  devise_for :users

  namespace :admin do
    resources :users
  end
  root to: "home#index"
  resources :connects, only: :index
  post '/voice' => 'connects#voice', as: :voice
end
