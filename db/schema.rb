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

ActiveRecord::Schema[7.1].define(version: 2025_11_25_123604) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", force: :cascade do |t|
    t.text "content"
    t.integer "question_number"
    t.bigint "assistant_session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_session_id"], name: "index_answers_on_assistant_session_id"
  end

  create_table "assistant_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "role"
    t.integer "current_question_number"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "time_limit"
    t.integer "time_taken"
    t.string "status"
    t.integer "total_score"
    t.text "strengths"
    t.text "weaknesses"
    t.text "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_assistant_sessions_on_user_id"
  end

  create_table "interview_answers", force: :cascade do |t|
    t.bigint "assistant_session_id", null: false
    t.integer "question_number"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_session_id"], name: "index_interview_answers_on_assistant_session_id"
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

  create_table "questions", force: :cascade do |t|
    t.bigint "assistant_session_id", null: false
    t.integer "number"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_session_id"], name: "index_questions_on_assistant_session_id"
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

  add_foreign_key "answers", "assistant_sessions"
  add_foreign_key "assistant_sessions", "users"
  add_foreign_key "interview_answers", "assistant_sessions"
  add_foreign_key "messages", "assistant_sessions"
  add_foreign_key "questions", "assistant_sessions"
end
