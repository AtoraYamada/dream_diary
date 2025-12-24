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

ActiveRecord::Schema[7.2].define(version: 2025_12_24_131855) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "dream_tags", comment: "DreamとTagの多対多関係", force: :cascade do |t|
    t.bigint "dream_id", null: false, comment: "夢日記ID"
    t.bigint "tag_id", null: false, comment: "タグID"
    t.datetime "created_at", null: false, comment: "作成日時・更新日時"
    t.datetime "updated_at", null: false, comment: "作成日時・更新日時"
    t.index ["dream_id", "tag_id"], name: "index_dream_tags_on_dream_id_and_tag_id", unique: true
    t.index ["dream_id"], name: "index_dream_tags_on_dream_id"
    t.index ["tag_id"], name: "index_dream_tags_on_tag_id"
  end

  create_table "dreams", comment: "夢日記の本体データ", force: :cascade do |t|
    t.bigint "user_id", null: false, comment: "ユーザーID"
    t.string "title", limit: 15, null: false, comment: "夢のタイトル（15文字制限）"
    t.text "content", null: false, comment: "夢の本文（10,000文字制限）"
    t.integer "emotion_color", null: false, comment: "感情彩色（enum: 0=peace, 1=chaos, 2=fear, 3=elation）"
    t.boolean "lucid_dream_flag", default: false, comment: "明晰夢フラグ"
    t.datetime "dreamed_at", null: false, comment: "夢を見た日"
    t.datetime "created_at", null: false, comment: "作成日時・更新日時"
    t.datetime "updated_at", null: false, comment: "作成日時・更新日時"
    t.index ["user_id", "dreamed_at"], name: "index_dreams_on_user_id_and_dreamed_at"
    t.index ["user_id", "emotion_color"], name: "index_dreams_on_user_id_and_emotion_color"
    t.index ["user_id", "title"], name: "index_dreams_on_user_id_and_title"
    t.index ["user_id"], name: "index_dreams_on_user_id"
  end

  create_table "tags", comment: "タグマスター（登場人物・場所）", force: :cascade do |t|
    t.bigint "user_id", null: false, comment: "ユーザーID"
    t.string "name", null: false, comment: "タグ名（元の表記）"
    t.string "yomi", null: false, comment: "読み仮名（ひらがな）"
    t.integer "yomi_index", null: false, comment: "五十音インデックス"
    t.integer "category", null: false, comment: "カテゴリ（enum: 0=person, 1=place）"
    t.datetime "created_at", null: false, comment: "作成日時・更新日時"
    t.datetime "updated_at", null: false, comment: "作成日時・更新日時"
    t.index ["user_id", "category"], name: "index_tags_on_user_id_and_category"
    t.index ["user_id", "name"], name: "index_tags_on_user_id_and_name", unique: true
    t.index ["user_id", "yomi"], name: "index_tags_on_user_id_and_yomi"
    t.index ["user_id", "yomi_index"], name: "index_tags_on_user_id_and_yomi_index"
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "users", comment: "ユーザー認証・管理", force: :cascade do |t|
    t.string "email", default: "", null: false, comment: "メールアドレス"
    t.string "username", null: false, comment: "ユーザー名"
    t.string "encrypted_password", default: "", null: false, comment: "暗号化パスワード"
    t.string "reset_password_token", comment: "パスワードリセット用トークン"
    t.datetime "reset_password_sent_at", comment: "リセット送信日時"
    t.datetime "remember_created_at", comment: "ログイン記憶日時"
    t.datetime "created_at", null: false, comment: "作成日時・更新日時"
    t.datetime "updated_at", null: false, comment: "作成日時・更新日時"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "dream_tags", "dreams"
  add_foreign_key "dream_tags", "tags"
  add_foreign_key "dreams", "users"
  add_foreign_key "tags", "users"
end
