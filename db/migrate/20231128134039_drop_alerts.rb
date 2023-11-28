class DropAlerts < ActiveRecord::Migration[7.0]
  def up
    drop_table :alerts
  end

  def down
    create_table "alerts", id: :serial, force: :cascade do |t|
      t.datetime "created_at", null: false
      t.text "description"
      t.integer "investigation_id"
      t.string "summary"
      t.datetime "updated_at", null: false
      t.index ["investigation_id"], name: "index_alerts_on_investigation_id"
    end
  end
end
