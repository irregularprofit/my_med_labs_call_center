class CreateMonthlyTotals < ActiveRecord::Migration
  def change
    create_table :monthly_totals do |t|
      t.date :date
      t.integer :duration, default: 0
      t.integer :user_id

      t.timestamps
    end

    add_column :call_logs, :monthly_total_id, :integer
  end
end
