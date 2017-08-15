class CreateUserAliases < ActiveRecord::Migration[5.0]
  def change
    create_table :user_aliases do |t|
      t.integer :user_id
      t.string :identifier
      t.string :source
      t.text :settings
      t.timestamps
    end
    
    add_index :user_aliases, [:identifier, :source], :unique => true
    add_index :user_aliases, [:user_id]
  end
end
