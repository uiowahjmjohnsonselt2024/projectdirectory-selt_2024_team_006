# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Shops', type: :request do
  let(:item) { create(:item) }

  describe 'GET /index' do
    it 'returns http success' do
      get '/shop'
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'POST /buy/:id' do
    it 'returns http success when buying an item' do
      post "/shop/buy/#{item.id}"
      expect(response).to have_http_status(:redirect)
    end

    it "doesn't allow purchase with insufficient shards" do
      user = create(:user, shards_balance: 0)
      sign_in user

      post "/shop/buy/#{item.id}"
      expect(response).to redirect_to(shop_index_path)
      follow_redirect!
      expect(flash[:alert]).to include('Not enough shards!')
    end
  end
end
