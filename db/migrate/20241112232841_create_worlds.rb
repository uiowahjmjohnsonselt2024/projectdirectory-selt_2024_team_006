# frozen_string_literal: true

class CreateWorlds < ActiveRecord::Migration[7.0]
  def change
    create_table :worlds do |t|
      t.string :name
      t.integer :creator_id

      t.timestamps
    end
  end
end
