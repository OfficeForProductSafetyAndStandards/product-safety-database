class CreateCsvExports < ActiveRecord::Migration[7.0]
  def change
    create_table :csv_exports do |t|
      t.datetime :started_at, null: false
      t.string :location, null: false
      t.timestamps
    end
  end
end
