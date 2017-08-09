class CreateWordCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :word_categories do |t|
      t.string :category
      t.string :locale
      t.float :random_id
      t.text :data
      t.timestamps
    end
    add_index :word_categories, [:category, :locale], :unique => true
    add_index :word_categories, [:random_id]
  end
end
