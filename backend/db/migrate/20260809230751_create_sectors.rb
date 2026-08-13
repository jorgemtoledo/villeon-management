class CreateSectors < ActiveRecord::Migration[8.1]
  def change
    create_table :sectors do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :sectors, :name, unique: true
  end
end
