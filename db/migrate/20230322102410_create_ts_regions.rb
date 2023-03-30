class CreateTsRegions < ActiveRecord::Migration[7.0]
  def up
    create_table :ts_regions do |t|
      t.timestamps
      t.column  :name, :string
      t.column  :acronym, :string
    end

    add_reference :organisations, :ts_region, index: false

    Rake::Task["organisations:add_ts_region_information"].invoke(Rails.root.join("lib/regulators/regulators.xlsx").to_s)
  end

  def down
    remove_reference :organisations, :ts_region

    drop_table :ts_regions
  end
end
