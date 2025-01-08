class DropTeamsUsers < ActiveRecord::Migration[5.2]
  def up
    # Check that all users have one team
    safety_assured do
      query = execute "SELECT count(*) FROM users WHERE (SELECT count(*) AS teams_count FROM teams_users WHERE teams_users.user_id=users.id) != 1"
      raise "Users with zero or more than one team exist - clean the data first" if query.first["count"] != 0
    end

    add_column :users, :team_id, :uuid, index: true
    add_foreign_key :users, :teams, validate: false

    safety_assured do
      execute "UPDATE users SET team_id=(SELECT team_id FROM teams_users WHERE user_id=users.id LIMIT 1)"

      # Add NOT NULL constraint once data has been migrated to avoid error
      change_column_null :users, :team_id, false
    end

    drop_table "teams_users"
  end

  def down
    create_table "teams_users", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.uuid "team_id"
      t.datetime "updated_at", null: false
      t.uuid "user_id"
      t.index %w[team_id], name: "index_teams_users_on_team_id"
      t.index %w[user_id], name: "index_teams_users_on_user_id"
    end

    safety_assured do
      execute "INSERT INTO teams_users (team_id, user_id, created_at, updated_at) (SELECT users.team_id, users.id, NOW(), NOW() FROM users);"
    end

    remove_column :users, :team_id
  end
end
