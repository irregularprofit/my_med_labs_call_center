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
  post '/queue' => 'connects#queue', as: :queue
  post '/dequeue' => 'connects#dequeue', as: :dequeue

  post '/init_conference' => 'connects#init_conference', as: :init_conference
  post '/conference' => 'connects#conference', as: :conference
  post '/check_rooms' => 'connects#check_rooms', as: :check_rooms
end
