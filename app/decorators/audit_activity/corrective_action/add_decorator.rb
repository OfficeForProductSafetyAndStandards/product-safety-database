class AuditActivity::CorrectiveAction::AddDecorator < AuditActivity::CorrectiveAction::BaseDecorator
  def online_recall_information
    h.online_recall_information_text_for(
      metadata.dig("updates", "online_recall_information", 1),
      has_online_recall_information: metadata.dig("updates", "has_online_recall_information", 1)
    )
  end
end
