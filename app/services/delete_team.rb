class DeleteTeam
  include Interactor

  delegate :team, :new_team, :user, to: :context

  def call
    context.fail!(error: "No team supplied") unless team.is_a?(Team)
    context.fail!(error: "No new team supplied to absorb cases and users") unless new_team.is_a?(Team)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "Team is already deleted") if team.deleted?
    context.fail!(error: "New team cannot be deleted") if new_team.deleted?

    ActiveRecord::Base.transaction do
      team.mark_as_deleted!
      team.users.update_all(team_id: new_team.id)
      team.owned_products.update_all(owning_team_id: new_team.id)
      remove_team_as_owner_from_cases
      remove_team_as_collaborator_from_cases
    end
  end

private

  def remove_team_as_owner_from_cases
    team.owner_collaborations.each do |collaboration|
      next change_case_ownership_when_owner_is_team(collaboration) if collaboration.investigation.owner == team

      change_case_ownership_when_owner_is_user_on_team(collaboration)
    end
  end

  def change_case_ownership_when_owner_is_team(collaboration)
    ChangeNotificationOwner.call!(
      notification: collaboration.investigation,
      owner: new_team,
      user:,
      rationale: change_case_owner_rationale,
      silent: true
    )
  end

  # In this case we want to retain the user as the owner, but change the OwnerTeam collaboration.
  def change_case_ownership_when_owner_is_user_on_team(collaboration)
    collaboration.investigation.collaboration_accesses.changeable.where(collaborator: new_team).destroy_all
    collaboration.update!(collaborator_id: new_team.id)

    metadata = update_owner_activity_class.build_metadata(new_team, change_case_owner_rationale)

    update_owner_activity_class.create!(
      added_by_user: user,
      investigation: collaboration.investigation,
      title: nil,
      body: nil,
      metadata:
    )
  end

  def update_owner_activity_class
    AuditActivity::Investigation::UpdateOwner
  end

  def remove_team_as_collaborator_from_cases
    team.collaboration_accesses.changeable.each do |collaboration|
      add_new_team_to_case(collaboration) unless new_team_already_collaborating?(collaboration.investigation)
      remove_team_from_case(collaboration)
    end
  end

  def new_team_already_collaborating?(investigation)
    investigation.collaboration_accesses.where(collaborator_id: new_team.id).exists?
  end

  def add_new_team_to_case(collaboration)
    AddTeamToCase.call!(
      investigation: collaboration.investigation,
      team: new_team,
      collaboration_class: collaboration.class,
      user:,
      message: add_remove_team_message,
      silent: true
    )
  end

  def remove_team_from_case(collaboration)
    RemoveTeamFromNotification.call!(
      collaboration:,
      user:,
      message: add_remove_team_message,
      silent: true
    )
  end

  def change_case_owner_rationale
    I18n.t("delete_team.change_case_owner_rationale", team: team_display_name, new_team: new_team_display_name, user: user_display_name)
  end

  def add_remove_team_message
    I18n.t("delete_team.add_remove_team_message", team: team_display_name, new_team: new_team_display_name, user: user_display_name)
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
