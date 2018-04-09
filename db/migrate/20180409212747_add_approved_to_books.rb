class AddApprovedToBooks < ActiveRecord::Migration[5.0]
  def change
    add_column :books, :approved, :boolean
    add_index :books, [:approved]
    Book.all.update_all(approved: true)
  end
end
