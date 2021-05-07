class AddUserToFocus < ActiveRecord::Migration[5.0]
  def change
    add_column :focus, :user_id, :integer
    add_column :focus, :approved, :boolean
  end
end
