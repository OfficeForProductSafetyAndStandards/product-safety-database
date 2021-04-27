class MigrateAuditActivityBusinessDestroyToMetadata < ActiveRecord::Migration[6.1]
  def up
    AuditActivity::Business::Destroy.where(metadata: nil).find_each(&:migrate_to_metadata)
  end
end
