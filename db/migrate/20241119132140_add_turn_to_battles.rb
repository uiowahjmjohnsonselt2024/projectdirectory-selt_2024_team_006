# frozen_string_literal: true

class AddTurnToBattles < ActiveRecord::Migration[7.0]
  def change
    add_column :battles, :turn, :string, default: 'player'
  end
end
