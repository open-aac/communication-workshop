class AddRefIdToFocus < ActiveRecord::Migration[5.0]
  def change
    add_column :focus, :ref_id, :string
    add_index :focus, [:ref_id], unique: true
  end
end
