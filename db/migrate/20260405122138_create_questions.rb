class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end
