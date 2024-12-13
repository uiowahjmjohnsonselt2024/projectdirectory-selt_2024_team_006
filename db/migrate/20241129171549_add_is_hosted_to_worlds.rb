# frozen_string_literal: true

class AddIsHostedToWorlds < ActiveRecord::Migration[7.0]
  def change
    add_column :worlds, :is_hosted, :boolean
  end
end
