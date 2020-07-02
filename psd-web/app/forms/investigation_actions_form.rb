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
      change_case_status: action_label("change_case_status.#{case_status}"),
      reassign: action_label(:reassign),
      change_case_visibility: action_label("change_case_visibility.#{visibility_status}")
    }
  end

  def email_alert_action
    return {} unless policy(investigation).send_email_alert?

    {
      send_email_alert: action_label(:send_email_alert),
    }
  end

  def visibility_status
    if investigation.is_private?
      "restricted"
    else
      "not_restricted"
    end
  end

  def case_status
    if investigation.is_closed?
      "closed"
    else
      "open"
    end
  end

  def action_label(action)
    I18n.t(action, scope: "forms.investigation_actions.actions")
  end
end
