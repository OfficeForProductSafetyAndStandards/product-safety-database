class MigrateSourceData < ActiveRecord::Migration[6.1]
  def up
    [Activity, Business, Contact, Location, Product].each do |model|
      add_column model.table_name, :added_by_user_id, :uuid, null: true
      ActiveRecord::Base.connection.execute("UPDATE #{model.table_name} SET added_by_user_id=sources.user_id FROM sources WHERE #{model.table_name}.id=sources.sourceable_id AND sources.sourceable_type='#{model}'")
    end

    drop_table :sources
  end

  def down
    create_table "sources", id: :serial, force: :cascade do |t|
      t.datetime "created_at", null: false
      t.string "name"
      t.integer "sourceable_id"
      t.string "sourceable_type"
      t.string "type"
      t.datetime "updated_at", null: false
      t.uuid "user_id"
      t.index %w[sourceable_id sourceable_type], name: "index_sources_on_sourceable_id_and_sourceable_type"
      t.index %w[user_id], name: "index_sources_on_user_id"
    end

    [Activity, Business, Contact, Location, Product].each do |model|
      model.all.find_each do |record|
        sql = ActiveRecord::Base.send(:sanitize_sql_array, ["INSERT INTO sources(sourceable_id,sourceable_type,user_id,created_at,updated_at) VALUES(?,?,?,?,NOW())", record.id, model, record.added_by_user_id, record.created_at])
        ActiveRecord::Base.connection.execute(sql)
      end
      remove_column model.table_name, :added_by_user_id
    end
  end
end
