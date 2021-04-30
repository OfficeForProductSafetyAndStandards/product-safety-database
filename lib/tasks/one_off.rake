namespace :db do
  namespace :migration do
    desc "Migrates AuditActivity::Business::Destroy to new metadata format"
    task business_removed_audit: :environment do
      AuditActivity::Business::Destroy.where(metadata: nil).find_each(&:migrate_to_metadata)
    end

    desc "AuditActivity::Business::Add4 to new metadata format"
    task business_added_audit: :environment do
      AuditActivity::Business::Add.where(metadata: nil).find_each(&:migrate_to_metadata)
    end
  end
end
