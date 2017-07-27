class AddRandomIdToWordData < ActiveRecord::Migration[5.0]
  def change
    add_column :word_data, :random_id, :integer
    add_index :word_data, [:random_id]
  end
end
