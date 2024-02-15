class ChangeNotificationCorrectiveActionTaken
  include Interactor
  include EntitiesToNotify

  delegate :notification, :corrective_action_taken, :corrective_action_not_taken_reason, :user, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No corrective action taken supplied") unless corrective_action_taken.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.corrective_action_not_taken_reason = nil unless corrective_action_taken == "other"

    notification.assign_attributes(corrective_action_taken:, corrective_action_not_taken_reason:)
    notification.save!
  end
end
