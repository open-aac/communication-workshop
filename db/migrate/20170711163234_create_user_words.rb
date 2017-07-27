class CreateUserWords < ActiveRecord::Migration[5.0]
  def change
    create_table :user_words do |t|
      t.string :word
      t.string :locale
      t.integer :user_id
      t.text :data
      t.timestamps
    end
    add_index :user_words, [:word, :locale, :user_id], :unique => true
  end
end
