class AddNotNullToJournalsItemId < ActiveRecord::Migration[8.1]
  def change
    change_column_null :journals, :item_id, false
  end
end
