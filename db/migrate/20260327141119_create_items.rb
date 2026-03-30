class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.text :thinking_note
      t.integer :status, null: false, default: 0
      t.integer :cooldown_duration

      t.datetime :cooldown_until
      t.datetime :notified_at
      t.datetime :decided_at

      t.references :user, null: false, foreign_key: true

      t.index :status

      t.timestamps
    end
  end
end
