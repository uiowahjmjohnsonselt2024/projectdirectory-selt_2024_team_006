# frozen_string_literal: true

class CreatePlayerProgress < ActiveRecord::Migration[7.0]
  def change
    create_table :player_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :achievement, null: false, foreign_key: true
      t.integer :current_progress
      t.boolean :claimed

      t.timestamps
    end
  end
end
