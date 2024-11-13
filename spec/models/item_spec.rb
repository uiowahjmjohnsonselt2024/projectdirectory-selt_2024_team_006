# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item, type: :model do
  let(:item) { Item.new(name: 'Sword', image_url: 'image_url', price: 10) }

  describe 'validations' do
    it 'is valid' do
      expect(item).to be_valid
    end

    it 'is not valid without a name' do
      item.name = nil
      expect(item).not_to be_valid
      expect(item.errors[:name]).to include("can't be blank")
    end

    it 'is not valid without an image_url' do
      item.image_url = nil
      expect(item).not_to be_valid
      expect(item.errors[:image_url]).to include("can't be blank")
    end

    it 'is not valid with a price less than or equal to 0' do
      item.price = 0
      expect(item).not_to be_valid
      expect(item.errors[:price]).to include('must be greater than 0')
    end

    it 'is not valid with a non integer price' do
      item.price = 'invalid'
      expect(item).not_to be_valid
      expect(item.errors[:price]).to include('is not a number')
    end
  end

  describe 'associations' do
    let(:user) { User.create!(email: 'test@example.com', password: 'password') }

    it 'has many user_items' do
      user_item1 = UserItem.create!(user: user, item: item)
      user_item2 = UserItem.create!(user: user, item: item)
      item.save
      expect(item.user_items).to include(user_item1, user_item2)
    end

    it 'has many users through user_items' do
      user1 = User.create!(email: 'user1@example.com', password: 'password')
      user2 = User.create!(email: 'user2@example.com', password: 'password')
      UserItem.create!(user: user1, item: item)
      UserItem.create!(user: user2, item: item)
      item.save
      expect(item.users).to include(user1, user2)
    end

    it 'destroys associated user_items when item is destroyed' do
      item.save
      user_item = UserItem.create!(user: user, item: item)
      item.destroy
      expect(UserItem.find_by(id: user_item.id)).to be_nil
    end
  end
end
