# frozen_string_literal: true

class AddTurnTrackingToBattles < ActiveRecord::Migration[7.0]
  def change
    add_column :battles, :current_turn, :integer
    add_column :battles, :turn_order, :text
  end
end
