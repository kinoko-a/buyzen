class RemoveIndexFromJournalsItemId < ActiveRecord::Migration[8.1]
  def change
    remove_index :journals, :item_id
  end
end
