# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :user_items, dependent: :destroy
  has_many :items, through: :user_items
  has_many :battles, foreign_key: :player_id
  has_many :user_world_states, dependent: :destroy

  after_initialize :set_default_shards_balance, if: :new_record?
  after_create :assign_default_sword

  def charge_shards(amount)
    return false if shards_balance < amount

    decrement!(:shards_balance, amount)
    true
  end

  private

  def set_default_shards_balance
    self.shards_balance ||= 0
  end

  def assign_default_sword
    default_sword = Item.find_by(name: 'Basic Dagger')
    user_items.create(item: default_sword) if default_sword.present?
  end
end
