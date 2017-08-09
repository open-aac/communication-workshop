class CreateUserAuths < ActiveRecord::Migration[5.0]
  def change
    create_table :user_auths do |t|
      t.integer :user_id
      t.text :settings
      t.timestamps
    end
    add_index :user_auths, [:user_id], :unique => true
  end
end
