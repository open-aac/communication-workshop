class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :hashed_email
      t.string :hashed_identifier
      t.text :settings
      t.timestamps
    end
    add_index :users, [:hashed_email]
    add_index :users, [:hashed_identifier]
  end
end
