class AuditActivity::Investigation::UpdateRiskLevelValidation < AuditActivity::Investigation::Base
  def self.from(*)
    raise "Deprecated - use UpdateRiskLevelValidation.call instead"
  end

  def self.build_metadata(investigation)
    updated_values = investigation.previous_changes.slice(:risk_validated_at).merge(investigation.previous_changes.slice(:risk_validated_by))

    {
      updates: updated_values
    }
  end

  def title(*)
    I18n.t("investigations.risk_validation.activity.success")
  end
end
