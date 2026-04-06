class AddDefaultToAnswersIsDraft < ActiveRecord::Migration[8.1]
  def change
    change_column_default :answers, :is_draft, true
    change_column_null :answers, :is_draft, false
  end
end
