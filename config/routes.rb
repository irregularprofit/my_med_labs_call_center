MyMedLabsCallCenter::Application.routes.draw do

  devise_for :users

  namespace :admin do
    resources :users
  end
  root to: "home#index"
  resources :connects, only: :index
  post '/voice' => 'connects#voice', as: :voice
  post '/enqueue' => 'connects#enqueue', as: :enqueue
  get '/wait_url' => 'connects#wait_url', as: :wait_url
  get '/queue' => 'connects#queue', as: :queue
  get '/about_to_connect' => 'connects#about_to_connect', as: :about_to_connect
end
