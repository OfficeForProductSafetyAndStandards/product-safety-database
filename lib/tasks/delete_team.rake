namespace :team do
  desc "Marks the given team as deleted, assigning their cases and users to another team"
  task delete: :environment do
    team = Team.find(ENV.fetch("ID"))
    new_team = Team.find(ENV.fetch("NEW_TEAM_ID"))
    user = User.find_by!(email: ENV.fetch("EMAIL"))

    result = DeleteTeam.call(team:, new_team:, user:)

    raise result.error unless result.success?

    puts "Team #{team.name} successfully marked as deleted."
    puts "Users and cases assigned to #{new_team.name}"
  end
end
