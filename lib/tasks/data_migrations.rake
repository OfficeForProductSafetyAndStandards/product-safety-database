namespace :data_migrations do
  desc "Marks the given team as deleted, assigning their cases and users to another team"
  task team_mappings: :environment do
    team_mappings ||= JSON.load_file!(Rails.root.join("app/assets/team-mappings.json"), object_class: OpenStruct)

    team_mappings.each do |team_mapping|
      team = Team.where(name: team_mapping.team_name).first
      next unless team

      team.update_columns(
        team_type: team_mapping.team_type&.strip,
        regulator_name: team_mapping.regulator_name&.strip,
        ts_region: team_mapping.ts_region&.strip,
        ts_acronym: team_mapping.ts_acronym&.strip,
        ts_area: team_mapping.ts_area&.strip
      )
    end
  end
end
