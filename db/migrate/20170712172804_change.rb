class Change < ActiveRecord::Migration[5.0]
  def change
    remove_index :word_data, [:random_id]
    remove_column :word_data, :random_id
    add_column :word_data, :random_id, :float
    add_index :word_data, [:random_id]
  end
end
