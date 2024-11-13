# frozen_string_literal: true

ActiveRecord::Schema[7.0].define(version: 20_241_112_232_841) do
  create_table 'items', force: :cascade do |t|
    t.string 'name'
    t.text 'description'
    t.integer 'price'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'image_url'
    t.integer 'damage' # Retaining the damage attribute
  end

  create_table 'user_items', force: :cascade do |t|
    t.integer 'user_id', null: false
    t.integer 'item_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['item_id'], name: 'index_user_items_on_item_id'
    t.index ['user_id'], name: 'index_user_items_on_user_id'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at'
    t.datetime 'remember_created_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.integer 'shards_balance'
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
  end

  create_table 'worlds', force: :cascade do |t|
    t.string 'name'
    t.integer 'creator_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  add_foreign_key 'user_items', 'items'
  add_foreign_key 'user_items', 'users'
end
