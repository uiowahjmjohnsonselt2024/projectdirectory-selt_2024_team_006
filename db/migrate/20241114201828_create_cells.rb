# frozen_string_literal: true

class CreateCells < ActiveRecord::Migration[7.0]
  def change
    create_table :cells do |t|
      t.integer :x
      t.integer :y
      t.references :world, null: false, foreign_key: true
      t.string :content

      t.timestamps
    end
  end
end
