# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { User.new(email: 'test@example.com', password: 'password') }

  describe 'callbacks' do
    context 'when a new user is created' do
      it 'sets default shards balance to 0' do
        user.save
        expect(user.shards_balance).to eq(0)
      end

      it 'assigns a default weapon' do
        Item.create!(name: 'Basic Dagger', price: 100, damage: 100, image_url: 'image_url')
        new_user = User.create!(email: 'test2@example.com', password: 'password')
        expect(new_user.items.pluck(:name)).to include('Basic Dagger')
      end
    end
  end

  describe 'associations' do
    it 'has many user_items' do
      user_item1 = UserItem.create!(user: user,
                                    item: Item.create!(name: 'Sword', price: 100,
                                                       damage: 100, image_url: 'image_url'))
      user_item2 = UserItem.create!(user: user,
                                    item: Item.create!(name: 'Shield', price: 100,
                                                       damage: 100, image_url: 'image_url'))
      expect(user.user_items).to include(user_item1, user_item2)
    end

    it 'has many items through user_items' do
      item1 = Item.create!(name: 'Sword', price: 100, damage: 100, image_url: 'image_url')
      item2 = Item.create!(name: 'Shield', price: 100, damage: 100, image_url: 'image_url')
      UserItem.create!(user: user, item: item1)
      UserItem.create!(user: user, item: item2)
      expect(user.items).to include(item1, item2)
    end

    it 'destroys associated user_items when user is destroyed' do
      item = Item.create!(name: 'Sword', price: 100, damage: 100, image_url: 'image_url')
      user_item = UserItem.create!(user: user, item: item)
      user.destroy
      expect(UserItem.find_by(id: user_item.id)).to be_nil
    end
  end
  describe '.from_omniauth' do
    let(:auth_hash) do
      OmniAuth::AuthHash.new(
        info: {
          email: 'test@example.com'
        }
      )
    end

    context 'when a user with the given email already exists' do
      let!(:existing_user) { create(:user, email: 'test@example.com') }

      it 'returns the existing user' do
        user = User.from_omniauth(auth_hash)
        expect(user).to eq(existing_user)
      end
    end

    context 'when a user with the given email does not exist' do
      it 'creates a new user and returns it' do
        expect do
          User.from_omniauth(auth_hash)
        end.to change(User, :count).by(1)

        new_user = User.last
        expect(new_user.email).to eq('test@example.com')
        expect(new_user.valid?).to be true
      end
    end
  end
end
