class AddNationBuilderId < ActiveRecord::Migration
  def change
    add_column :rosters, :nation_builder_id, :integer
    add_column :rosters, :email, :string
  end
end
