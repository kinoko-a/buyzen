class AddColumnsToItems < ActiveRecord::Migration[8.1]
  def change
    change_table :items, bulk: true do |t|
      t.integer :desire_level
      t.integer :current_mood
    end
  end
end
