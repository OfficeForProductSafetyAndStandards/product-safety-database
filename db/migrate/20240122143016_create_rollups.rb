class CreateRollups < ActiveRecord::Migration[7.0]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :rollups do |t|
      t.string :name, null: false
      t.string :interval, null: false
      t.datetime :time, null: false
      t.jsonb :dimensions, null: false, default: {}
      t.float :value
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
    add_index :rollups, %i[name interval time dimensions], unique: true
  end
end
