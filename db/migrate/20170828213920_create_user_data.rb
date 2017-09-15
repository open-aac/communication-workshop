class CreateUserData < ActiveRecord::Migration[5.0]
  def change
    create_table :user_data do |t|
      t.integer :user_id
      t.text :data

      t.timestamps
    end
    add_index :user_data, [:user_id], :unique => true
  end
end
