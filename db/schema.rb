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

ActiveRecord::Schema[7.1].define(version: 2025_09_07_154837) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "mark_enum", ["-", "+", "0"]

  create_table "categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.boolean "is_default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.decimal "amount"
    t.string "description"
    t.date "occurred_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "incomes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "source"
    t.decimal "amount"
    t.date "received_on"
    t.boolean "is_work_income"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_incomes_on_user_id"
  end

  create_table "monthly_category_reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.date "month_start"
    t.decimal "total_spent"
    t.decimal "total_life_energy_hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "monthly_review_id", null: false
    t.enum "received_fulfillment", default: "0", null: false, enum_type: "mark_enum"
    t.enum "aligned_with_values", default: "0", null: false, enum_type: "mark_enum"
    t.enum "would_change_post_fi", default: "0", null: false, enum_type: "mark_enum"
    t.index ["category_id"], name: "index_monthly_category_reviews_on_category_id"
    t.index ["monthly_review_id"], name: "index_monthly_category_reviews_on_monthly_review_id"
    t.index ["user_id"], name: "index_monthly_category_reviews_on_user_id"
  end

  create_table "monthly_reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "month_start"
    t.decimal "total_income"
    t.decimal "total_expenses"
    t.decimal "total_life_energy_hours"
    t.boolean "completed"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "month_code"
    t.index ["user_id", "month_code"], name: "index_monthly_reviews_on_user_id_and_month_code", unique: true
    t.index ["user_id"], name: "index_monthly_reviews_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "hourly_wage", precision: 10, scale: 2
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "categories", "users"
  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "users"
  add_foreign_key "incomes", "users"
  add_foreign_key "monthly_category_reviews", "categories"
  add_foreign_key "monthly_category_reviews", "monthly_reviews"
  add_foreign_key "monthly_category_reviews", "users"
  add_foreign_key "monthly_reviews", "users"
end
