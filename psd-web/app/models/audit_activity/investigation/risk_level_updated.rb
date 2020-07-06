class AuditActivity::Investigation::RiskLevelUpdated < AuditActivity::Investigation::Base
  I18N_SCOPE = "audit_activity.investigation.risk_level_updated".freeze
  SUBTITLE_SLUG="Risk level changed".freeze

  def self.from(*)
    raise "Deprecated - use .create_for! instead"
  end

  def self.create_for!(investigation, action:, source:)
    create!(
      source: source,
      investigation: investigation,
      metadata: build_metadata(investigation, action)
    )
  end

  private_class_method def self.build_metadata(investigation, action)
    change = investigation.previous_changes[:risk_level]
    {
      previous_risk_level: change&.first,
      new_risk_level: change&.second,
      action: action
    }
  end

  def title(_user)
    I18n.t(".title.#{metadata['action']}", level: metadata["new_risk_level"]&.downcase, scope: I18N_SCOPE)
  end

private

  def subtitle_slug
    SUBTITLE_SLUG
  end

  def notify_relevant_users
    entities_to_notify.each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.case_risk_level_updated(
        email: email,
        name: entity.name,
        investigation: investigation,
        action: metadata["action"],
        level: metadata["new_risk_level"]
      ).deliver_later
    end
  end
end
