namespace :team do
  desc "Marks the given team as deleted, assigning their cases and users to another team"
  task delete: :environment do
    team = Team.find(ENV.fetch("ID", nil))
    new_team = Team.find(ENV.fetch("NEW_TEAM_ID", nil))
    user = User.find_by!(email: ENV.fetch("EMAIL", nil))

    result = DeleteTeam.call(team: team, new_team: new_team, user: user)

    raise result.error unless result.success?

    puts "Team #{team.name} successfully marked as deleted."
    puts "Users and cases assigned to #{new_team.name}"
  end
end
