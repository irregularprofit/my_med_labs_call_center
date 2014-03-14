class CreateSchedule < ActiveRecord::Migration
  def change
    create_table :schedules do |t|
      t.integer :start_day
      t.integer :start_hour
      t.integer :start_min

      t.integer :end_day
      t.integer :end_hour
      t.integer :end_min

      t.integer :user_id

      t.boolean :enabled

      t.timestamps
    end
  end
end
