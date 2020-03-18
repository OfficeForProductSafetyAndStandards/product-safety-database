class GenerateUuidForOrganizationsTeamsAndUsers < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_column_default(:organisations, :id, from: nil, to: "gen_random_uuid()")
      change_column_default(:users, :id, from: nil, to: "gen_random_uuid()")
      change_column_default(:teams, :id, from: nil, to: "gen_random_uuid()")
    end
  end
end
