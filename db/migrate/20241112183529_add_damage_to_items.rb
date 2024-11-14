# frozen_string_literal: true

class AddDamageToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :damage, :integer
  end
end
