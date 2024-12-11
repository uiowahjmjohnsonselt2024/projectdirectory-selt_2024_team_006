# frozen_string_literal: true

class AddDefaultValuesToPlayerProgress < ActiveRecord::Migration[7.0]
  def change
    change_column_default :player_progresses, :current_progress, 0
    change_column_default :achievements, :target, 0
  end
end
