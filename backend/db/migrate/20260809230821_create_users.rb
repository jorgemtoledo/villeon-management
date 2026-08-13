class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      ## Devise :database_authenticatable, :recoverable, :rememberable — full
      ## auth wiring (JWT, sessions) comes in a later block; these columns just
      ## keep the table shape compatible with it from the start.
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      t.string :name, null: false
      t.string :role, null: false, default: "operator"
      t.references :sector, null: true, foreign_key: true
      t.boolean :active, null: false, default: true

      t.timestamps

      t.check_constraint "role IN ('admin', 'manager', 'operator')", name: "users_role_check"
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
