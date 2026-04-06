class AddUniqueIndexToAnswers < ActiveRecord::Migration[8.1]
  def change
    add_index :answers, [:item_id, :question_id], unique: true
  end
end
