# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_24_071052) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "answers", force: :cascade do |t|
    t.integer "choice"
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.bigint "question_id", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id", "question_id"], name: "index_answers_on_item_id_and_question_id", unique: true
    t.index ["item_id"], name: "index_answers_on_item_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "items", force: :cascade do |t|
    t.integer "cooldown_duration"
    t.datetime "cooldown_until"
    t.datetime "created_at", null: false
    t.integer "current_mood"
    t.datetime "decided_at"
    t.integer "desire_level"
    t.string "name", null: false
    t.text "note"
    t.datetime "notified_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["status"], name: "index_items_on_status"
    t.index ["user_id"], name: "index_items_on_user_id"
  end

  create_table "journals", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.datetime "updated_at", null: false
  end

  create_table "questions", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id", "position"], name: "index_questions_on_user_id_and_position", unique: true
    t.index ["user_id"], name: "index_questions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "answers", "items"
  add_foreign_key "answers", "questions"
  add_foreign_key "items", "users"
  add_foreign_key "journals", "items"
  add_foreign_key "questions", "users"
end
