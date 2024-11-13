# frozen_string_literal: true

class Item < ApplicationRecord
  validates :name, presence: true
  validates :image_url, presence: true
  validates :price, numericality: { greater_than: 0 }

  has_many :user_items, dependent: :destroy
  has_many :users, through: :user_items
end
