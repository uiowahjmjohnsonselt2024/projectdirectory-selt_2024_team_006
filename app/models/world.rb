# frozen_string_literal: true

class World < ApplicationRecord
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  has_many :cells, dependent: :destroy
  after_create :generate_grid

  private

  def generate_grid
    grid_size = 7
    player_position = [0, 0]
    treasure_positions, enemy_positions = assign_positions(grid_size, player_position)

    create_cells(grid_size, player_position, treasure_positions, enemy_positions)
  end

  def assign_positions(grid_size, player_position)
    all_positions = (0...grid_size).to_a.product((0...grid_size).to_a)
    available_positions = all_positions - [player_position]

    treasure_positions = available_positions.sample(5)
    available_positions -= treasure_positions

    enemy_positions = available_positions.sample(5)
    [treasure_positions, enemy_positions]
  end

  def create_cells(grid_size, player_position, treasure_positions, enemy_positions)
    (0...grid_size).each do |x|
      (0...grid_size).each do |y|
        cells.create(x: x, y: y, content: cell_content(x, y, player_position, treasure_positions, enemy_positions))
      end
    end
  end

  def cell_content(x_pos, y_pos, player_position, treasure_positions, enemy_positions)
    position = [x_pos, y_pos]
    return 'player' if position == player_position
    return 'treasure' if treasure_positions.include?(position)
    return 'enemy' if enemy_positions.include?(position)

    'empty'
  end
end
