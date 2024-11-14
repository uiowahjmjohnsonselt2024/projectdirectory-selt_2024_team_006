# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShopController, type: :controller do
  let(:user) { create(:user, shards_balance: 100) }
  let!(:item1) { create(:item, name: 'Basic Sword', price: 50) }
  let!(:item2) { create(:item, name: 'Advanced Sword', price: 100) }

  before { sign_in user }

  describe 'GET #index' do
    it 'loads all the items' do
      get :index
      expect(assigns(:items)).to match_array([item1, item2])
      expect(response).to render_template(:index)
    end
  end

  describe 'POST #buy' do
    context 'when the user has enough shards' do
      it 'allows the user to buy an item' do
        expect do
          post :buy, params: { id: item1.id }
        end.to change { user.user_items.count }.by(1)

        expect(flash[:notice]).to eq("Successfully bought #{item1.name}!")
        user.reload
        expect(user.shards_balance).to eq(50)
        expect(response).to redirect_to(shop_index_path)
      end
    end

    context 'when the user does not have enough shards' do
      let(:user) { create(:user, shards_balance: 30) }

      it 'does not allow the user to buy the item' do
        post :buy, params: { id: item1.id }

        expect(flash[:alert]).to eq('Not enough shards!')
        expect(response).to redirect_to(shop_index_path)
      end
    end

    context 'when the user already owns the item' do
      before do
        user.user_items.create(item: item1)
      end

      it 'allows the user to sell the item' do
        post :buy, params: { id: item1.id }

        user.reload
        expect(user.shards_balance).to eq(138)
        expect(response).to redirect_to(shop_index_path)
      end
    end
  end
end
