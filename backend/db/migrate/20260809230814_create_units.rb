class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.string :name, null: false
      t.string :abbreviation, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :units, :abbreviation, unique: true
  end
end
