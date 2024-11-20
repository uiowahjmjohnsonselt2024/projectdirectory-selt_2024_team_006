# frozen_string_literal: true

class Cell < ApplicationRecord
  belongs_to :world
  has_one :battle

  validates :world, presence: true
  validates :x, :y, :content, presence: true
end
