class CreateLessons < ActiveRecord::Migration[5.0]
  def change
    create_table :lessons do |t|
      t.string :module_id
      t.boolean :required
      t.boolean :root
      t.text :data

      t.timestamps
    end
    add_index :lessons, [:module_id]
  end
end
