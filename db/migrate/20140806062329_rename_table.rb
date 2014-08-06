class RenameTable < ActiveRecord::Migration
  def change
    rename_table :user_devices, :devices
  end
end
