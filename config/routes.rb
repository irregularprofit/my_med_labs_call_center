MyMedLabsCallCenter::Application.routes.draw do
  devise_for :users

  namespace :admin do
    resources :users
    resources :logs, only: :index
    resources :monthly_totals, only: :index
  end
  root to: "home#index"
  resources :connects, only: :index

  post '/enqueue' => 'connects#enqueue', as: :enqueue
  get '/wait_url' => 'connects#wait_url', as: :wait_url
  post '/queue' => 'connects#queue', as: :queue
  post '/about_to_connect' => 'connects#about_to_connect', as: :about_to_connect

  post '/init_conference' => 'connects#init_conference', as: :init_conference
  post '/conference' => 'connects#conference', as: :conference
  post '/check_rooms' => 'connects#check_rooms', as: :check_rooms
  post '/dial' => 'connects#dial', as: :dial

  post '/check_logs' => 'connects#check_logs', as: :check_logs
end
