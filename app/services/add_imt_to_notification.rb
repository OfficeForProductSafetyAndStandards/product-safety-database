class AddImtToNotification
  include Interactor
  include EntitiesToNotify

  delegate :notification, :user, to: :context

  # OPSS IMT is automatically added to an notification with edit permissions
  #  if either the risk level is serious/high or
  # the corrective action indicates a recall or modification programme. If OPSS IMT has already been added,
  # `AddTeamToNotification` returns silently.
  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    actions = notification.corrective_actions&.pluck("action")
    return unless should_add_team?(actions)

    team = Team.find_by(name: "OPSS Incident Management")
    return if team.blank?

    AddTeamToNotification.call!(
      notification:,
      team:,
      collaboration_class: Collaboration::Access::Edit,
      user:,
      message: "System added OPSS IMT with edit permissions due to either risk level or corrective action."
    )
  end

private

  def should_add_team?(actions)
    %w[serious high].include?(notification.risk_level) ||
      actions&.include?("recall_of_the_product_from_end_users") ||
      actions&.include?("modification_programme")
  end
end
