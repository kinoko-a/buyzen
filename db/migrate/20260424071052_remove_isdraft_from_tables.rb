class RemoveIsdraftFromTables < ActiveRecord::Migration[8.1]
  def change
    remove_column :answers,  :is_draft
    remove_column :journals, :is_draft
  end
end
