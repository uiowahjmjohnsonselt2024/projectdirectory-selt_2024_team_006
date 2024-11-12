# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_initialize :set_default_shards_balance, if: :new_record?

  private

  def set_default_shards_balance
    self.shards_balance ||= 0
  end
end
