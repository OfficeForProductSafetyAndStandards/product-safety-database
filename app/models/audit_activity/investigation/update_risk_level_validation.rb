class AuditActivity::Investigation::UpdateRiskLevelValidation < AuditActivity::Investigation::Base
  def self.build_metadata(investigation, rationale)
    updated_values = investigation.previous_changes.slice(:risk_validated_at).merge(investigation.previous_changes.slice(:risk_validated_by))

    {
      updates: updated_values,
      rationale: sanitize_text(rationale)
    }
  end

  def title(*)
    if metadata.dig("updates", "risk_validated_at", 1)
      I18n.t("investigations.risk_validation.activity.added")
    else
      I18n.t("investigations.risk_validation.activity.removed")
    end
  end

  def body
    metadata["rationale"]
  end
end
