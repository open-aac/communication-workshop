class CreateBooks < ActiveRecord::Migration[5.0]
  def change
    create_table :books do |t|
      t.string :ref_id
      t.string :locale
      t.float :random_id
      t.integer :user_id
      t.text :data
      t.timestamps
    end
    add_index :books, [:ref_id], :unique => true
    add_index :books, [:user_id]
  end
end
