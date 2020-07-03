class AuditActivity::Investigation::UpdateRiskLevel < AuditActivity::Investigation::Base
  I18N_SCOPE = "audit_activity.investigation.update_risk_level".freeze

  def self.from(investigation, action:, source:)
    metadata = build_metadata(investigation, action)
    create!(
      source: source,
      investigation: investigation,
      metadata: metadata
    )
  end

  private_class_method def self.build_metadata(investigation, action)
    {
      risk_level: investigation.risk_level,
      action: action
    }
  end

  def title(_user)
    I18n.t(".title.#{metadata['action']}", level: metadata["risk_level"].downcase, scope: I18N_SCOPE)
  end

private

  def subtitle_slug
    "Risk level changed"
  end

  def notify_relevant_users
    entities_to_notify.each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.case_risk_level_updated(
        email: email,
        name: entity.name,
        investigation: investigation,
        action: metadata["action"],
        level: metadata["risk_level"]
      ).deliver_later
    end
  end
end
