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

ActiveRecord::Schema[7.2].define(version: 2025_04_27_180647) do
  create_table "inspections", force: :cascade do |t|
    t.datetime "inspection_date"
    t.datetime "reinspection_date"
    t.string "inspector"
    t.string "serial"
    t.string "description"
    t.string "location"
    t.integer "equipment_class"
    t.boolean "visual_pass"
    t.integer "fuse_rating"
    t.decimal "earth_ohms"
    t.integer "insulation_mohms"
    t.decimal "leakage"
    t.boolean "passed"
    t.text "comments"
    t.string "image_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["serial"], name: "index_inspections_on_serial"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
  end
end
