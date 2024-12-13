# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  get 'single_player', to: 'games#single_player'
  get 'new_world', to: 'games#new_world'
  get 'users/achievements', to: 'users#achievements', as: 'achievements'
  post 'worlds', to: 'games#create'
  get 'games/:id', to: 'games#show', as: 'game'
  delete 'single_player/:id', to: 'games#destroy', as: 'destroy'
  resources :worlds, only: [:create]

  root 'home#index'

  resources :games do
    member do
      post :join
    end
  end

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

  resources :users do
    collection do
      post 'claim_achievement', to: 'users#claim_achievement'
    end
  end
end
