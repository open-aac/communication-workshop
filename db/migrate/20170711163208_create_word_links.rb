class CreateWordLinks < ActiveRecord::Migration[5.0]
  def change
    create_table :word_links do |t|
      t.integer :word_id
      t.integer :link_id
      t.string :link_type
      t.string :link_purpose
      t.timestamps
    end
    add_index :word_links, [:word_id, :link_id, :link_type, :link_purpose], :unique => true, :name => 'word_links_lookup_index'
  end
end
