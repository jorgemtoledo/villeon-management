class AddAllSectorsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :all_sectors, :boolean, default: false, null: false
  end
end
