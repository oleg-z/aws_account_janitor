# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160127194754) do

  create_table "aws_accounts", force: :cascade do |t|
    t.string   "alias"
    t.string   "access_key"
    t.string   "secret_key"
    t.string   "role"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "account_id"
    t.string   "email"
    t.string   "identifier"
    t.text     "billing_bucket"
    t.integer  "spending_threshold"
  end

  create_table "aws_data", force: :cascade do |t|
    t.string   "type"
    t.string   "region"
    t.text     "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "aws_records", force: :cascade do |t|
    t.string   "data_type"
    t.string   "aws_region"
    t.text     "data"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "account_id"
    t.text     "billing_bucket"
  end

  create_table "aws_usage_records", force: :cascade do |t|
    t.string   "data_type"
    t.string   "account_id"
    t.date     "date"
    t.text     "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settings", force: :cascade do |t|
    t.string "field_name"
    t.string "field_value"
  end

end
