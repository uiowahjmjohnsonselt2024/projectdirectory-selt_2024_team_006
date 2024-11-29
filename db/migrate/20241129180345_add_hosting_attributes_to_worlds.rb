class AddHostingAttributesToWorlds < ActiveRecord::Migration[7.0]
  def change
    add_column :worlds, :host_ip, :string
  end
end
