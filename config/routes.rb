# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  #sSingle Player Routes
  get 'single_player', to: 'games#single_player'
  get 'new_world', to: 'games#new_world'
  post 'worlds', to: 'games#create'
  get 'games/:id', to: 'games#show', as: 'game'
  delete 'single_player/:id', to: 'games#destroy', as: 'destroy'
  resources :worlds, only: [:create]

  #Multiplayer routes
  get 'multiplayer', to: 'multiplayer#index', as: 'multiplayer'
  get 'multiplayer/host', to: 'multiplayer#host', as: 'host_multiplayer'
  get 'multiplayer/join', to: 'multiplayer#join', as: 'join_multiplayer'

  root 'home#index'

  resources :worlds do
    post 'move', on: :member
    post 'resolve_battle', on: :member
    post 'attack_with_item', on: :member
  end

  get 'shards/purchase', to: 'shards#new', as: 'new_shards_purchase'
  post 'shards/purchase', to: 'shards#create', as: 'shards_purchase'
  post 'shards/fetch_rate', to: 'shards#fetch_rate'

  resources :shop, only: [:index]
  post 'shop/buy/:id', to: 'shop#buy', as: 'buy_item'

  get 'user/inventory', to: 'users#inventory', as: 'user_inventory'

  get 'profile', to: 'users#show', as: 'user_profile'
end
