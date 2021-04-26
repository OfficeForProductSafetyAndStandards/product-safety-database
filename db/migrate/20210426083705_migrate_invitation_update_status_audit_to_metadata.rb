class MigrateInvitationUpdateStatusAuditToMetadata < ActiveRecord::Migration[6.1]
  def up
    AuditActivity::Investigation::UpdateStatus.where(metadata: nil).find_each(&:migrate_to_metadata)
  end
end
