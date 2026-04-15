class AddUniqueDraftIndexToJournals < ActiveRecord::Migration[8.1]
  def change
    add_index :journals,
              [:item_id],
              unique: true,
              where: "is_draft = true",
              name: "index_journals_unique_draft_per_item"
  end
end
