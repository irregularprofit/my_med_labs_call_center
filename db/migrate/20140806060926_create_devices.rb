class CreateDevices < ActiveRecord::Migration
  def change
    create_table :user_devices do |t|

      t.integer :user_id

      t.string :device_id

      t.timestamps
    end
  end
end
