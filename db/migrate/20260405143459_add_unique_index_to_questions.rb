class AddUniqueIndexToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_index :questions, [:user_id, :position], unique: true
  end
end
