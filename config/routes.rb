MyMedLabsCallCenter::Application.routes.draw do
  devise_for :users

  devise_scope :user do
    namespace :api do

      post "users/sign_in" => 'sessions#create'
      delete "users/sign_out" => 'sessions#destroy'
      get "users/get_token" => 'sessions#get_token'
      get "users/user_on_call" => 'sessions#user_on_call'

    end
  end
  namespace :admin do
    resources :users
    resources :schedules
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

  post '/check_logs' => 'connects#check_logs', as: :check_logs
end
