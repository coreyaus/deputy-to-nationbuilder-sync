class AddStateColumnToRoster < ActiveRecord::Migration
  def change
    add_column :rosters, :state, :string
  end
end
