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

ActiveRecord::Schema.define(version: 2021_06_23_041005) do

  create_table "active_webhook_error_logs", force: :cascade do |t|
    t.integer "subscription_id"
    t.string "job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "active_webhook_subscriptions", force: :cascade do |t|
    t.integer "topic_id"
    t.text "callback_url"
    t.text "shared_secret"
    t.datetime "disabled_at"
    t.string "disabled_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "active_webhook_topics", force: :cascade do |t|
    t.string "key"
    t.string "version"
    t.datetime "disabled_at"
    t.string "disabled_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

end
