# frozen_string_literal: true

class AddDescriptionToAchievements < ActiveRecord::Migration[7.0]
  def change
    add_column :achievements, :description, :string
  end
end
