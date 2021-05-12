class AddPopularityToBooksAndFocus < ActiveRecord::Migration[5.0]
  def change
    add_column :books, :popularity, :float
    add_column :focus, :popularity, :float
  end
end
