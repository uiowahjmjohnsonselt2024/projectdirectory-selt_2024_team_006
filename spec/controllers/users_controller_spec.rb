# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { User.create!(email: 'test@example.com', password: 'password') }
  let(:item1) { Item.create!(name: 'Sword', image_url: 'url', price: 10) }
  let(:item2) { Item.create!(name: 'Shield', image_url: 'url', price: 15) }

  before do
    sign_in user
    user.items << [item1, item2]
  end

  describe 'GET #show' do
    it 'authenticates the user' do
      sign_out user
      get :show
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'assigns @user as the current user' do
      get :show
      expect(assigns(:user)).to eq(user)
    end

    it 'assigns @inventory_items with the users items' do
      get :show
      expect(assigns(:inventory_items)).to match_array([item1, item2])
    end

    it 'renders the show template' do
      get :show
      expect(response).to render_template(:show)
    end
  end
end
