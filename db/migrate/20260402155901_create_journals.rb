class CreateJournals < ActiveRecord::Migration[8.1]
  def change
    create_table :journals do |t|
      t.text :content
      t.boolean :is_draft, null: false, default: true

      t.references :item, foreign_key: true

      t.timestamps
    end
  end
end
