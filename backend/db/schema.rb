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

ActiveRecord::Schema[7.2].define(version: 2026_05_18_161001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "tournament_id", null: false
    t.bigint "category_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_type_id"], name: "index_categories_on_category_type_id"
    t.index ["tournament_id"], name: "index_categories_on_tournament_id"
  end

  create_table "category_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "gender", null: false
    t.boolean "team", default: false, null: false
    t.string "rank"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_category_types_on_name", unique: true
  end

  create_table "competitors", force: :cascade do |t|
    t.string "name", null: false
    t.integer "age"
    t.string "province"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "disciplines", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_disciplines_on_name", unique: true
  end

  create_table "match_events", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.integer "competitor_id", null: false
    t.string "side", null: false
    t.string "event_type", null: false
    t.string "at_second"
    t.integer "point_index_for_side"
    t.boolean "match_winning", default: false, null: false
    t.integer "penalty_to"
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competitor_id"], name: "index_match_events_on_competitor_id"
    t.index ["event_type"], name: "index_match_events_on_event_type"
    t.index ["match_id"], name: "index_match_events_on_match_id"
    t.index ["side"], name: "index_match_events_on_side"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "shiajo_id", null: false
    t.bigint "rule_set_id", null: false
    t.integer "red_competitor_id"
    t.integer "white_competitor_id"
    t.integer "winner_id"
    t.integer "max_time", null: false
    t.integer "best_of_points", null: false
    t.string "draw_system", null: false
    t.string "status", default: "upcoming", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", null: false
    t.bigint "red_source_match_id"
    t.bigint "white_source_match_id"
    t.index ["category_id"], name: "index_matches_on_category_id"
    t.index ["red_source_match_id"], name: "index_matches_on_red_source_match_id"
    t.index ["rule_set_id"], name: "index_matches_on_rule_set_id"
    t.index ["shiajo_id", "position"], name: "index_matches_on_shiajo_id_and_position", unique: true
    t.index ["shiajo_id", "status"], name: "index_matches_on_shiajo_id_and_status"
    t.index ["shiajo_id"], name: "index_matches_on_shiajo_id"
    t.index ["status"], name: "index_matches_on_status"
    t.index ["white_source_match_id"], name: "index_matches_on_white_source_match_id"
  end

  create_table "rule_sets", force: :cascade do |t|
    t.string "name", null: false
    t.integer "max_time", null: false
    t.integer "best_of_points", null: false
    t.string "draw_system", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_rule_sets_on_name", unique: true
  end

  create_table "seasons", force: :cascade do |t|
    t.string "name"
    t.integer "year"
    t.bigint "discipline_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discipline_id"], name: "index_seasons_on_discipline_id"
  end

  create_table "shiajos", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "category_id", null: false
    t.integer "current_match_id"
    t.boolean "active", default: true, null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_shiajos_on_category_id"
    t.index ["current_match_id"], name: "index_shiajos_on_current_match_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "title", null: false
    t.string "region"
    t.boolean "official", default: true, null: false
    t.string "tournament_type", null: false
    t.date "starts_on"
    t.date "ends_on"
    t.bigint "season_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["season_id"], name: "index_tournaments_on_season_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.boolean "is_admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "categories", "category_types"
  add_foreign_key "categories", "tournaments"
  add_foreign_key "match_events", "competitors", on_delete: :nullify
  add_foreign_key "match_events", "matches"
  add_foreign_key "matches", "categories"
  add_foreign_key "matches", "competitors", column: "red_competitor_id", on_delete: :nullify
  add_foreign_key "matches", "competitors", column: "white_competitor_id", on_delete: :nullify
  add_foreign_key "matches", "competitors", column: "winner_id", on_delete: :nullify
  add_foreign_key "matches", "matches", column: "red_source_match_id", on_delete: :nullify
  add_foreign_key "matches", "matches", column: "white_source_match_id", on_delete: :nullify
  add_foreign_key "matches", "rule_sets"
  add_foreign_key "matches", "shiajos"
  add_foreign_key "seasons", "disciplines"
  add_foreign_key "shiajos", "categories"
  add_foreign_key "tournaments", "seasons"
end
