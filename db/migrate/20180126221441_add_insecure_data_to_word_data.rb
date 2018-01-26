class AddInsecureDataToWordData < ActiveRecord::Migration[5.0]
  def change
    add_column :word_data, :insecure_data, :text
    WordData.all.each do |word|
      word.insecure_data = word.data
      word.save
    end
  end
end
