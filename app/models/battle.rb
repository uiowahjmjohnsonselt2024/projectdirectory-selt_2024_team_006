# frozen_string_literal: true

class Battle < ApplicationRecord
  belongs_to :world
  belongs_to :cell
  belongs_to :player, class_name: 'User'

  serialize :turn_order, Array # Store turn order as an array in the database

  validates :state, inclusion: { in: %w[active won lost] }
  def initialize_turn_order
    self.turn_order = world.users.pluck(:id) # All players in the world
    self.current_turn = turn_order.first     # Start with the first player
    save!
  end

  # Rotate to the next player's turn
  def next_turn
    current_index = turn_order.index(current_turn)
    self.current_turn = turn_order[(current_index + 1) % turn_order.size]
    save!
  end

  # Check if it's the specified user's turn
  def player_turn?(user)
    current_turn == user.id
  end

  def resolve(result)
    update!(state: result)
    destroy
  end

  def toggle_turn
    self.turn = turn == player.id.to_s ? 'enemy' : player.id.to_s
    save!
  end
end
