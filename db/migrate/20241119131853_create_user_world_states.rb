# frozen_string_literal: true

class CreateUserWorldStates < ActiveRecord::Migration[7.0]
  def change
    create_table :user_world_states do |t|
      t.references :user, null: false, foreign_key: true
      t.references :world, null: false, foreign_key: true
      t.integer :health

      t.timestamps
    end
  end
end
