class InvestigationActionsForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pundit::Authorization

  attribute :investigation_action
  attribute :investigation
  attribute :current_user

  validates_presence_of :investigation_action

  def actions
    status_and_owner_actions
  end

private

  def status_and_owner_actions
    return {} unless policy(investigation).change_owner_or_status?

    case_status_action.merge({
      change_case_owner: action_label(:change_case_owner),
      change_case_visibility: action_label("change_case_visibility.#{visibility_status}"),
      change_case_risk_level: action_label("change_case_risk_level.#{risk_level_status}")
    })
  end

  def case_status_action
    if investigation.is_closed?
      { reopen_case: action_label("reopen_case") }
    else
      { close_case: action_label("close_case") }
    end
  end

  def risk_level_status
    if investigation.risk_level
      "set"
    else
      "not_set"
    end
  end

  def visibility_status
    if investigation.is_private
      "restricted"
    else
      "unrestricted"
    end
  end

  def action_label(action)
    I18n.t(action, scope: "forms.investigation_actions.actions")
  end
end
