# frozen_string_literal: true

class World < ApplicationRecord
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  has_many :cells, dependent: :destroy
  after_create :generate_grid

  private

  def generate_grid
    (0..6).each do |x|
      (0..6).each do |y|
        cells.create(x: x, y: y, content: 'empty') # or set default content
      end
    end
  end
end
