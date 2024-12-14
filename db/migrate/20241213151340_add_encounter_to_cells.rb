# frozen_string_literal: true

class AddEncounterToCells < ActiveRecord::Migration[7.0]
  def change
    add_column :cells, :encounter, :text
  end
end
