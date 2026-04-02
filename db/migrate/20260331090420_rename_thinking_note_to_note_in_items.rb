class RenameThinkingNoteToNoteInItems < ActiveRecord::Migration[8.1]
  def change
    rename_column :items, :thinking_note, :note
  end
end
