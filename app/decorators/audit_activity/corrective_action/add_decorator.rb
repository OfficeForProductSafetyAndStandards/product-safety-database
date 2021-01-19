class AuditActivity::CorrectiveAction::AddDecorator < AuditActivity::CorrectiveAction::BaseDecorator
  def online_recall_information
    h.online_recall_information_text_for(
      metadata.dig("updates", "online_recall_information", 1),
      has_online_recall_information: metadata.dig("updates", "has_online_recall_information", 1)
    )
  end

  def attached_image?
    attachment&.image?
  end

  def attachment
    @attachment ||= (signed_id = metadata.dig("updates", "existing_document_id", 1)) && ActiveStorage::Blob.find_signed!(signed_id)
  end
end
