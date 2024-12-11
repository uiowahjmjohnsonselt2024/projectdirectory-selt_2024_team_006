# frozen_string_literal: true

class CreateAchievements < ActiveRecord::Migration[7.0]
  def change
    create_table :achievements do |t|
      t.string :name
      t.integer :target
      t.integer :reward

      t.timestamps
    end
  end
end
