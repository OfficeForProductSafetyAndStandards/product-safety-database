desc "Add case creators as collaborators (if not assignee)"
task add_case_creators_as_collaborators: :environment do
  count = 0
  Investigation.find_each do |investigation|
    creator_team = investigation.creator_team
    next unless creator_team

    creator_user = investigation.creator_user
    owner_team = investigation.owner_team
    teams_with_access = investigation.teams_with_access

    if creator_team != owner_team && !teams_with_access.include?(creator_team)
      count += 1

      puts "Adding #{creator_team.name} as a collaborator to case #{investigation.pretty_id}"
      investigation.edit_access_collaborations.create!(collaborator: creator_team, added_by_user: creator_user)
    end
  end

  puts "Done. #{count} teams added to cases as collaborators"
end
