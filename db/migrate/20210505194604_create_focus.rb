class CreateFocus < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  def change
    create_table :focus do |t|
      t.string :title
      t.string :category
      t.string :locale
      t.string :search_string, limit: 10000
      t.text :data
      t.timestamps
    end
    add_index :focus, [:locale, :category, :title]
    enable_extension "btree_gin"
    execute "CREATE INDEX CONCURRENTLY focus_search_string ON focus USING GIN(to_tsvector('simple', COALESCE(search_string::TEXT,'')))"
    add_column :books, :search_string, :string, limiit: 10000
    execute "CREATE INDEX CONCURRENTLY books_search_string ON books USING GIN(to_tsvector('simple', COALESCE(search_string::TEXT,'')))"
  end
end
