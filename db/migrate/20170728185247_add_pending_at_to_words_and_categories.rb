class AddPendingAtToWordsAndCategories < ActiveRecord::Migration[5.0]
  def change
    add_column :word_data, :pending_since, :datetime
    add_column :word_categories, :pending_since, :datetime
  end
end
