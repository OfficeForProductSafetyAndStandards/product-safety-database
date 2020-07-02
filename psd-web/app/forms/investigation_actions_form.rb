class InvestigationActionsForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pundit

  attribute :action
  attribute :investigation
  attribute :current_user

  validates_presence_of :action

  def actions
    status_and_owner_actions.merge(email_alert_action)
  end

private

  def status_and_owner_actions
    return {} unless policy(investigation).change_owner_or_status?

    {
      change_case_status: (investigation.is_closed? ? "Reopen case" : "Close case"),
      reassign: "Reassign this case",
      change_case_visibility: (investigation.is_private? ? "Restrict this case" : "Unrestrict this case")
    }
  end

  def email_alert_action
    return {} unless policy(investigation).send_email_alert?

    {
      send_email_alert: "Send email alert"
    }
  end
end
