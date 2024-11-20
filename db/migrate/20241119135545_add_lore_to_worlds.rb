# frozen_string_literal: true

class AddLoreToWorlds < ActiveRecord::Migration[7.0]
  def change
    add_column :worlds, :lore, :text
  end
end
