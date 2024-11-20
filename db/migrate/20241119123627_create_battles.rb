# frozen_string_literal: true

class CreateBattles < ActiveRecord::Migration[7.0]
  def change
    create_table :battles do |t|
      t.references :world, null: false, foreign_key: true
      t.references :cell, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: { to_table: :users }
      t.string :state, null: false, default: 'active'
      t.json :enemy_data, default: {}
      t.json :player_data, default: {}

      t.timestamps
    end

    add_index :battles, %i[player_id world_id], unique: true
  end
end
