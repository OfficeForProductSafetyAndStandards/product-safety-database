class CreateAccidentOrIncidents < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      create_table :accident_or_incidents do |t|
        t.date :date
        t.boolean :is_date_known
        t.integer :product_id
        t.integer :investigation_id
        t.string :severity_other
        t.text :additional_info

        t.timestamps
      end
    end
  end
end
