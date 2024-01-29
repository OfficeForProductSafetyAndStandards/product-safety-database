class AuditActivity::CorrectiveAction::AddDecorator < AuditActivity::CorrectiveAction::BaseDecorator
  def online_recall_information
    h.online_recall_information_text_for(
      metadata.dig("corrective_action", "online_recall_information"),
      has_online_recall_information: metadata.dig("corrective_action", "has_online_recall_information")
    )
  end

  def attachment
    @attachment ||= (document_id = metadata.dig("document", "id")) && ActiveStorage::Blob.find_by(id: document_id)
  end

  def date_decided
    @date_decided ||= Date.parse(metadata.dig("corrective_action", "date_decided")).to_formatted_s(:govuk)
  end

  def legislation
    return [] unless (legislation = metadata.dig("corrective_action", "legislation"))

    legislation.to_sentence
  end

  def details
    metadata.dig("corrective_action", "details")
  end

  def measure_type
    CorrectiveAction.human_attribute_name("measure_type.#{metadata.dig('corrective_action', 'measure_type')}")
  end

  def duration
    CorrectiveAction.human_attribute_name("duration.#{metadata.dig('corrective_action', 'duration')}")
  end

  def geographic_scopes
    return [] unless (scopes = metadata.dig("corrective_action", "geographic_scopes"))

    scopes.map { |geographic_scope|
      I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes])
    }.to_sentence
  end
end
