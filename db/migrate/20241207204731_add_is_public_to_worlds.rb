# frozen_string_literal: true

class AddIsPublicToWorlds < ActiveRecord::Migration[7.0]
  def change
    add_column :worlds, :is_public, :boolean
  end
end
