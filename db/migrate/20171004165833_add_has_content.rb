class AddHasContent < ActiveRecord::Migration[5.0]
  def change
    add_column :word_data, :has_content, :boolean
    add_column :word_categories, :has_content, :boolean
    add_index :word_data, [:has_content, :random_id]
    add_index :word_categories, [:has_content, :random_id]
  end
end
