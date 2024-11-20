# frozen_string_literal: true

class Battle < ApplicationRecord
  belongs_to :world
  belongs_to :cell
  belongs_to :player, class_name: 'User'

  validates :state, inclusion: { in: %w[active won lost] }

  def resolve(result)
    update!(state: result)
    destroy
  end

  def toggle_turn
    self.turn = turn == 'player' ? 'enemy' : 'player'
    save!
  end
end
