class AddCallTypeToCallLog < ActiveRecord::Migration
  def change
    add_column :call_logs, :call_type, :string
    add_column :call_logs, :to, :string
  end
end
