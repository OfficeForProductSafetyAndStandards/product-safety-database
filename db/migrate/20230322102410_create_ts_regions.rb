class CreateTsRegions < ActiveRecord::Migration[7.0]
  def up
    create_table :ts_regions do |t|
      t.timestamps
      t.column  :name, :string
      t.column  :acronym, :string
    end

    add_reference :teams, :ts_region, index: false

    Rake::Task["teams:add_ts_region_information"].invoke(Rails.root.join("lib/regulators/regulators.xlsx").to_s)
  end

  def down
    remove_reference :teams, :ts_region

    drop_table :ts_regions
  end
end
