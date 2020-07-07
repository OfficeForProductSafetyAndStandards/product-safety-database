class AuditActivity::Investigation::RiskLevelUpdated < AuditActivity::Investigation::Base
  I18N_SCOPE = "audit_activity.investigation.risk_level_updated".freeze
  SUBTITLE_SLUG = "Risk level changed".freeze

  def self.from(*)
    raise "Deprecated - use .create_for! instead"
  end

  def self.create_for!(investigation, update_verb:, source:)
    create!(
      source: source,
      investigation: investigation,
      metadata: build_metadata(investigation, update_verb)
    )
  end

  private_class_method def self.build_metadata(investigation, update_verb)
    change = investigation.previous_changes[:risk_level]
    {
      previous_risk_level: change&.first,
      new_risk_level: change&.second,
      update_verb: update_verb
    }
  end

  def title(_user)
    I18n.t(".title.#{metadata['update_verb']}", level: metadata["new_risk_level"]&.downcase, scope: I18N_SCOPE)
  end

private

  def subtitle_slug
    SUBTITLE_SLUG
  end

  # Do not send investigation_updated mail. This is handled by the ChangeCaseRiskLevel service
  def notify_relevant_users; end
end
