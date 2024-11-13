# frozen_string_literal: true

Rails.application.routes.draw do
  root 'home#index'
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get 'single_player', to: 'games#single_player'
  get 'new_world', to: 'games#new_world'
  post 'worlds', to: 'games#create'
  get 'games/:id', to: 'games#show', as: 'game'
  resources :worlds, only: [:create]
  # Defines the root path route ("/")
  # root "articles#index"
end
