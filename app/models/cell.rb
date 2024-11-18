# frozen_string_literal: true

class Cell < ApplicationRecord
  belongs_to :world

  validates :world, presence: true
  validates :x, :y, :content, presence: true
end
