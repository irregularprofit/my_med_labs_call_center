class CreateCallLogs < ActiveRecord::Migration
  def change
    create_table :call_logs do |t|
      t.integer     :user_id
      t.integer     :duration
      t.timestamp   :start_time
      t.timestamp   :end_time
      t.string      :from
      t.string      :sid

      t.timestamps
    end
  end
end
