class AuditActivity::CorrectiveAction::UpdateDecorator < AuditActivity::CorrectiveAction::BaseDecorator
  def new_action
    action = metadata.dig("updates", "action", 1)
    return new_other_action if action == "other"

    CorrectiveAction.actions[action]
  end

  def new_summary
    metadata.dig("updates", "summary", 1)
  end

  def new_date_decided
    Date.parse(metadata.dig("updates", "date_decided", 1)).to_formatted_s(:govuk) rescue nil # rubocop:disable Style/RescueModifier
  end

  def new_legislation
    metadata.dig("updates", "legislation", 1)
  end

  def new_online_recall_information
    if (online_recall_information = metadata.dig("updates", "online_recall_information", 1)).present?
      return h.link_to "#{online_recall_information} (opens in new tab)", online_recall_information, rel: "noreferrer noopener", target: "_blank" if valid_url?(online_recall_information)

      return online_recall_information
    end

    has_online_recall_information = metadata.dig("updates", "has_online_recall_information", 1)
    return if has_online_recall_information.nil?

    if has_online_recall_information.inquiry.has_online_recall_information_no? || has_online_recall_information.inquiry.has_online_recall_information_not_relevant?
      I18n.t(".#{has_online_recall_information}", scope: %i[investigations corrective_actions helper has_online_recall_information])
    end
  end

  def new_duration
    metadata.dig("updates", "duration", 1)
  end

  def new_details
    metadata.dig("updates", "details", 1)
  end

  def new_measure_type
    metadata.dig("updates", "measure_type", 1)
  end

  def new_geographic_scopes
    return unless (geographic_scopes = metadata.dig("updates", "geographic_scopes", 1))

    geographic_scopes.map { |geographic_scope| I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes]) }.to_sentence
  end

  def further_details_changed?
    metadata["updates"].key?("details")
  end

  def new_filename
    metadata.dig("updates", "filename", 1)
  end

  def old_filename
    metadata.dig("updates", "filename", 0)
  end

  def file_description_changed?
    metadata["updates"].key?("file_description")
  end

  def new_file_description
    metadata.dig("updates", "file_description", 1)
  end

  def investigation_product_updated?
    metadata.dig("updates", "investigation_product_id", 1)
  end

  def business_updated?
    metadata.dig("updates", "business_id")
  end

  def new_business
    Business.find(metadata.dig("updates", "business_id", 1))
  end

private

  def new_other_action
    metadata.dig("updates", "other_action", 1)
  end

  def valid_url?(online_recall_information)
    uri = URI.parse(online_recall_information)
    uri.is_a?(URI::HTTP) && !uri.host.nil?
  rescue URI::InvalidURIError
    false
  end
end
