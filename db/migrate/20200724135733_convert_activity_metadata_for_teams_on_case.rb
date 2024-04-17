class ConvertActivityMetadataForTeamsOnCase < ActiveRecord::Migration[5.2]
  def change
    AuditActivity::Investigation::TeamAdded.where.not(title: nil).find_each do |activity|
      team_name = activity.attributes["title"].match(/(.*) added to/).captures.first.strip
      team = Team.find_by!(name: team_name)

      collaboration = Collaboration::Access::Edit.new(collaborator: team, investigation: activity.investigation)

      activity.update!(
        metadata: activity.class.build_metadata(collaboration, activity.body),
        body: nil,
        title: nil
      )
    end

    AuditActivity::Investigation::TeamDeleted.where.not(title: nil).find_each do |activity|
      team_name = activity.attributes["title"].match(/(.*) removed from/).captures.first.strip
      team = Team.find_by!(name: team_name)

      activity.update!(
        metadata: activity.class.build_metadata(team, activity.body),
        body: nil,
        title: nil
      )
    end
  end
end
