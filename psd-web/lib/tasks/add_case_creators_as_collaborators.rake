desc "Add case creators as collaborators (if not assignee)"
task add_case_creators_as_collaborators: :environment do
  count = 0
  Investigation.find_each do |investigation|
    creator = investigation.source.user
    creator_team = creator.team
    assignee_team = investigation.assignee_team
    collaborator_teams = investigation.teams

    if creator_team != assignee_team && !collaborator_teams.include?(creator_team)
      count += 1

      puts "Adding #{creator_team.name} as a collaborator to case #{investigation.pretty_id}"
      investigation.collaborators.create!(team: creator_team, added_by_user: creator, include_message: false)
    end
  end

  puts "Done. #{count} teams added to cases as collaborators"
end
