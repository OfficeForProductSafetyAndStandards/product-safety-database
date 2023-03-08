class MigrateMetadataOfAuditTrails < ActiveRecord::Migration[7.0]
  def self.up
    MigrateMetadataForAuditTrails.call
  end

  def self.down
    # This migration is non-reversible
  end
end
