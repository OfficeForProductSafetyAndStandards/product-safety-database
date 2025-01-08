class AuditActivity::CorrectiveAction::Update < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action, changes)
    {
      corrective_action_id: corrective_action.id,
      updates: changes.except("document")
    }
  end

  def self.migrate_geographic_scope!(audit_activity)
    return unless (geographic_scope_updates = audit_activity.metadata.dig("updates", "geographic_scope"))

    audit_activity.metadata["updates"]["geographic_scopes"] =
      geographic_scope_updates
        .map { |geographic_scope| CorrectiveAction::GEOGRAPHIC_SCOPES_MIGRATION_MAP[geographic_scope] }

    audit_activity.save!
  end

  # TODO: remove once migrated
  def metadata
    migrate_metadata_structure
  end

  def title(_user = nil)
    "Corrective action"
  end

  def subtitle_slug
    "Edited"
  end

  def corrective_action
    @corrective_action ||= if (corrective_action_id = metadata&.dig("corrective_action_id"))
                             CorrectiveAction.find_by!(id: corrective_action_id)
                           else
                             super
                           end
  end

  def attachment
    @attachment ||= (signed_id = metadata.dig("updates", "existing_document_file_id", 1)) && ActiveStorage::Blob.find_signed!(signed_id)
  end

private

  # TODO: remove once migrated
  def migrate_metadata_structure
    metadata = self[:metadata]

    product_id = metadata.dig("updates", "product_id")
    return metadata if product_id.blank?

    metadata["updates"]["investigation_product_id"] = product_id.map { |id| investigation.investigation_products.where(product_id: id).pick("investigation_products.id") }
    metadata["updates"].delete("product_id")
    metadata
  end
end
