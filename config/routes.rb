# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  root 'home#index'

  get 'shards/purchase', to: 'shards#new', as: 'new_shards_purchase'
  post 'shards/purchase', to: 'shards#create', as: 'shards_purchase'
  post 'shards/fetch_rate', to: 'shards#fetch_rate'
end
