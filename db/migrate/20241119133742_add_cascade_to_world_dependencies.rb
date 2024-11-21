# frozen_string_literal: true

class AddCascadeToWorldDependencies < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :battles, :worlds
    add_foreign_key :battles, :worlds, on_delete: :cascade

    remove_foreign_key :cells, :worlds
    add_foreign_key :cells, :worlds, on_delete: :cascade

    remove_foreign_key :user_world_states, :worlds
    add_foreign_key :user_world_states, :worlds, on_delete: :cascade
  end
end
