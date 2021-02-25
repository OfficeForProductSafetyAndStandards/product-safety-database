class ReconcileCorrectiveActionWithoutDocumentAttached < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up do
          without_attachment = audit_activities.select { |a| a.investigation.corrective_actions.any? { |ca| !ca.document.attached? } }
          without_attachment.each do |audit_activity|
            corrective_actions = audit_activity.investigation.corrective_actions.reject { |ca| ca.document.attached? }.sort_by(&:created_at)
            audits = audit_activity.investigation.activities.where(type: AuditActivity::CorrectiveAction::Add.to_s).select { |a| a.corrective_action.nil? }.sort_by(&:created_at)
            if corrective_actions.size != audits.size
              Rails.logger.tagged(self.class.to_s) { "Eisenbug detected: for investigation: #{audit_activity.investigation_id}" }
            else
              audits.zip(corrective_actions).each do |audit, corrective_action|
                audit.metadata["corrective_action"]["id"] = corrective_action.id
                audit.save!
              end
            end
          end
        end
      end
    end
  end

private

  def audit_activities
    @audit_activities ||= AuditActivity::CorrectiveAction::Add.where("metadata->'corrective_action'->'id' IS NULL").load
  end
end
