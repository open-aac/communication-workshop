# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20210506180150) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "btree_gin"

  create_table "books", force: :cascade do |t|
    t.string   "ref_id"
    t.string   "locale"
    t.float    "random_id"
    t.integer  "user_id"
    t.text     "data"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.boolean  "approved"
    t.string   "search_string"
    t.index "to_tsvector('simple'::regconfig, COALESCE((search_string)::text, ''::text))", name: "books_search_string", using: :gin
    t.index ["approved"], name: "index_books_on_approved", using: :btree
    t.index ["ref_id"], name: "index_books_on_ref_id", unique: true, using: :btree
    t.index ["user_id"], name: "index_books_on_user_id", using: :btree
  end

  create_table "focus", force: :cascade do |t|
    t.string   "title"
    t.string   "category"
    t.string   "locale"
    t.string   "search_string", limit: 10000
    t.text     "data"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "user_id"
    t.boolean  "approved"
    t.string   "ref_id"
    t.index "to_tsvector('simple'::regconfig, COALESCE((search_string)::text, ''::text))", name: "focus_search_string", using: :gin
    t.index ["locale", "category", "title"], name: "index_focus_on_locale_and_category_and_title", using: :btree
    t.index ["ref_id"], name: "index_focus_on_ref_id", unique: true, using: :btree
  end

  create_table "lessons", force: :cascade do |t|
    t.string   "module_id"
    t.boolean  "required"
    t.boolean  "root"
    t.text     "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["module_id"], name: "index_lessons_on_module_id", using: :btree
  end

  create_table "progresses", force: :cascade do |t|
    t.text     "settings"
    t.string   "nonce"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["nonce"], name: "index_progresses_on_nonce", using: :btree
  end

  create_table "settings", force: :cascade do |t|
    t.string   "key"
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text     "data"
    t.index ["key"], name: "index_settings_on_key", unique: true, using: :btree
  end

  create_table "user_aliases", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "identifier"
    t.string   "source"
    t.text     "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier", "source"], name: "index_user_aliases_on_identifier_and_source", unique: true, using: :btree
    t.index ["user_id"], name: "index_user_aliases_on_user_id", using: :btree
  end

  create_table "user_auths", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_auths_on_user_id", unique: true, using: :btree
  end

  create_table "user_data", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_data_on_user_id", unique: true, using: :btree
  end

  create_table "user_images", force: :cascade do |t|
    t.text     "settings"
    t.string   "nonce"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_words", force: :cascade do |t|
    t.string   "word"
    t.string   "locale"
    t.integer  "user_id"
    t.text     "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["word", "locale", "user_id"], name: "index_user_words_on_word_and_locale_and_user_id", unique: true, using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "hashed_email"
    t.string   "hashed_identifier"
    t.text     "settings"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["hashed_email"], name: "index_users_on_hashed_email", using: :btree
    t.index ["hashed_identifier"], name: "index_users_on_hashed_identifier", using: :btree
  end

  create_table "word_categories", force: :cascade do |t|
    t.string   "category"
    t.string   "locale"
    t.float    "random_id"
    t.text     "data"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.datetime "pending_since"
    t.boolean  "has_content"
    t.index ["category", "locale"], name: "index_word_categories_on_category_and_locale", unique: true, using: :btree
    t.index ["has_content", "random_id"], name: "index_word_categories_on_has_content_and_random_id", using: :btree
    t.index ["random_id"], name: "index_word_categories_on_random_id", using: :btree
  end

  create_table "word_data", force: :cascade do |t|
    t.string   "word"
    t.string   "locale"
    t.text     "old_data"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.float    "random_id"
    t.datetime "pending_since"
    t.boolean  "has_content"
    t.text     "data"
    t.boolean  "has_baseline_content"
    t.index ["has_baseline_content"], name: "index_word_data_on_has_baseline_content", using: :btree
    t.index ["has_content", "random_id"], name: "index_word_data_on_has_content_and_random_id", using: :btree
    t.index ["random_id"], name: "index_word_data_on_random_id", using: :btree
    t.index ["word", "locale"], name: "index_word_data_on_word_and_locale", unique: true, using: :btree
  end

  create_table "word_links", force: :cascade do |t|
    t.integer  "word_id"
    t.integer  "link_id"
    t.string   "link_type"
    t.string   "link_purpose"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["word_id", "link_id", "link_type", "link_purpose"], name: "word_links_lookup_index", unique: true, using: :btree
  end

end
