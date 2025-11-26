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

ActiveRecord::Schema[7.1].define(version: 2025_11_26_205136) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assistant_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.integer "current_question_number", default: 1
    t.datetime "started_at"
    t.datetime "ends_at"
    t.string "status", default: "in_progress"
    t.integer "total_score"
    t.text "strengths"
    t.text "weaknesses"
    t.text "summary"
    t.text "ai_feedback"
    t.index ["user_id"], name: "index_assistant_sessions_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "assistant_session_id", null: false
    t.string "role"
    t.text "content"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_session_id"], name: "index_messages_on_assistant_session_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "assistant_sessions", "users"
  add_foreign_key "messages", "assistant_sessions"
end
