class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.references :item, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :choice
      t.boolean :is_draft

      t.timestamps
    end
  end
end
