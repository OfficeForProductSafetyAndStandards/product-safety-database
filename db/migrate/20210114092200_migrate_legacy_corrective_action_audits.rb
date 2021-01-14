class MigrateLegacyCorrectiveActionAudits < ActiveRecord::Migration[6.1]
  def change
    AuditActivity::CorrectiveAction::Base.pluck(:ids)
  end
end
