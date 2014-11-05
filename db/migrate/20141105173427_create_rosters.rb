class CreateRosters < ActiveRecord::Migration
  def change
    create_table :rosters do |t|
      t.integer :shift_id
      t.integer :employee_id
      t.string :comments
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end
  end
end
