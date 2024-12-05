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

ActiveRecord::Schema[7.0].define(version: 2024_12_05_053304) do
  create_table "achievements", force: :cascade do |t|
    t.string "name"
    t.integer "target"
    t.integer "reward"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "battles", force: :cascade do |t|
    t.integer "world_id", null: false
    t.integer "cell_id", null: false
    t.integer "player_id", null: false
    t.string "state", default: "active", null: false
    t.json "enemy_data", default: {}
    t.json "player_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "turn", default: "player"
    t.index ["cell_id"], name: "index_battles_on_cell_id"
    t.index ["player_id", "world_id"], name: "index_battles_on_player_id_and_world_id", unique: true
    t.index ["player_id"], name: "index_battles_on_player_id"
    t.index ["world_id"], name: "index_battles_on_world_id"
  end

  create_table "cells", force: :cascade do |t|
    t.integer "x"
    t.integer "y"
    t.integer "world_id", null: false
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["world_id"], name: "index_cells_on_world_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_url"
    t.integer "damage"
  end

  create_table "player_progresses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "achievement_id", null: false
    t.integer "current_progress"
    t.boolean "claimed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["achievement_id"], name: "index_player_progresses_on_achievement_id"
    t.index ["user_id"], name: "index_player_progresses_on_user_id"
  end

  create_table "user_items", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_user_items_on_item_id"
    t.index ["user_id"], name: "index_user_items_on_user_id"
  end

  create_table "user_world_states", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "world_id", null: false
    t.integer "health"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_world_states_on_user_id"
    t.index ["world_id"], name: "index_user_world_states_on_world_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shards_balance"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "worlds", force: :cascade do |t|
    t.string "name"
    t.integer "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "lore"
    t.string "background_image_url"
  end

  add_foreign_key "battles", "cells"
  add_foreign_key "battles", "users", column: "player_id"
  add_foreign_key "battles", "worlds", on_delete: :cascade
  add_foreign_key "cells", "worlds", on_delete: :cascade
  add_foreign_key "player_progresses", "achievements"
  add_foreign_key "player_progresses", "users"
  add_foreign_key "user_items", "items"
  add_foreign_key "user_items", "users"
  add_foreign_key "user_world_states", "users"
  add_foreign_key "user_world_states", "worlds", on_delete: :cascade
end
