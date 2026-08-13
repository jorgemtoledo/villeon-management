class AddJtiToUsers < ActiveRecord::Migration[8.1]
  def change
    # Default "" only so the NOT NULL column can be added safely; every
    # AR-created row gets a real UUID from Devise::JWT::RevocationStrategies::JTIMatcher's
    # before_create callback (`unless jti.present?` treats "" as blank).
    add_column :users, :jti, :string, null: false, default: ""
    add_index :users, :jti, unique: true
  end
end
