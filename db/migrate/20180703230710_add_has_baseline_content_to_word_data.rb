class AddHasBaselineContentToWordData < ActiveRecord::Migration[5.0]
  def change
    add_column :word_data, :has_baseline_content, :boolean
    add_index :word_data, [:has_baseline_content]
    WordData.where(has_content: true).update_all(has_baseline_content: true)
  end
end
