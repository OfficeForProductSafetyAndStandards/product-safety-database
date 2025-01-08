class CreateAccidentOrIncidents < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      create_table :unexpected_events do |t|
        t.date :date
        t.boolean :is_date_known
        t.integer :product_id, null: false
        t.integer :investigation_id, null: false
        t.string :severity_other
        t.text :additional_info
        t.string :type, null: false

        t.timestamps
      end
    end
  end
end
