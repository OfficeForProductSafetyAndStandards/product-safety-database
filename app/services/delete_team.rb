class DeleteTeam
  include Interactor

  delegate :team, :new_team, :user, to: :context

  def call
    context.fail!(error: "No team supplied") unless team.is_a?(Team)
    context.fail!(error: "No new team supplied") unless new_team.is_a?(Team)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "Team cannot already be deleted") if team.deleted?
    context.fail!(error: "New team cannot already be deleted") if new_team.deleted?

    ActiveRecord::Base.transaction do
      team.mark_as_deleted!
      team.users.update_all(team_id: new_team.id)
      remove_team_as_owner_from_cases
      remove_team_as_collaborator_from_cases
    end
  end

private

  def remove_team_as_owner_from_cases
    team.owner_collaborations.each do |collaboration|
      next change_case_owner(collaboration.investigation) if collaboration.investigation.owner == team # Team is the ultimate owner
      collaboration.update!(collaborator_id: new_team.id) # User on the team is the ultimate owner
    end
  end

  def change_case_owner(investigation)
    ChangeCaseOwner.call!(
      investigation: investigation,
      owner: new_team,
      user: user,
      rationale: change_case_owner_rationale,
      silent: true
    )
  end

  def remove_team_as_collaborator_from_cases
    team.collaboration_accesses.changeable.each do |collaboration|
      investigation = collaboration.investigation
      add_new_team_to_case(investigation, collaboration.class) unless new_team_already_collaborating?(investigation)

      remove_team_from_case(collaboration)
    end
  end

  def new_team_already_collaborating?(investigation)
    investigation.collaboration_accesses.find_by(collaborator_id: new_team.id).present?
  end

  def add_new_team_to_case(investigation, collaboration_class)
    AddTeamToCase.call!(
      investigation: investigation,
      team: new_team,
      collaboration_class: collaboration_class,
      user: user,
      message: add_remove_team_message,
      silent: true
    )
  end

  def remove_team_from_case(collaboration)
    RemoveTeamFromCase.call!(
      collaboration: collaboration,
      user: user,
      message: add_remove_team_message,
      silent: true
    )
  end

  def change_case_owner_rationale
    "#{team_display_name} was merged into #{new_team_display_name} by #{user_display_name}. #{team_display_name} previously owned this case."
  end

  def add_remove_team_message
    "#{team_display_name} was merged into #{new_team_display_name} by #{user_display_name}. #{team_display_name} previously had access to this case."
  end

  def team_display_name
    team.decorate.display_name(viewer: new_team)
  end

  def new_team_display_name
    new_team.decorate.display_name(viewer: new_team)
  end

  def user_display_name
    user.decorate.display_name(viewer: new_team)
  end
end
