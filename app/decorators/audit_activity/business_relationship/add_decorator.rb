class AuditActivity::BusinessRelationship::AddDecorator < AuditActivity::CorrectiveAction::BaseDecorator
  def trading_name
    activity.metadata["trading_name"]
  end

  def relationship
    activity.metadata["relationship"]
  end
end
