class RenameWordDataColumnToOldData < ActiveRecord::Migration[5.0]
  def change
    rename_column :word_data, :data, :old_data
    rename_column :word_data, :insecure_data, :data
  end
end
