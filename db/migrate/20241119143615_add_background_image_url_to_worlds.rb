# frozen_string_literal: true

class AddBackgroundImageUrlToWorlds < ActiveRecord::Migration[7.0]
  def change
    add_column :worlds, :background_image_url, :string
  end
end
