class AddPublicToBooks < ActiveRecord::Migration[5.0]
  def change
    add_column :books, :public, :boolean
    add_index :books, [:public, :user_id, :approved]
    Book.all.each{|b| b.public = true; b.save }
  end
end
