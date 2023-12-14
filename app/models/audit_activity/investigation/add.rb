class AuditActivity::Investigation::Add < AuditActivity::Investigation::Base
  def self.build_metadata(investigation)
    {
      owner_id: investigation.owner&.id,
      complainant_id: investigation.complainant&.id,
      investigation: {
        title: investigation.decorate.title,
        coronavirus_related: investigation.coronavirus_related?,
        description: investigation.description,
        hazard_type: investigation.hazard_type,
        product_category: investigation.product_category
      }
    }
  end

  # owner may change after investigation was created, so we retrieve from the
  # metadata stored at the time of creation
  def owner
    User.find_by(id: metadata["owner_id"]) if metadata
  end

  # complainant may change after investigation was created, so we retrieve from
  # the metadata stored at the time of creation
  def complainant
    Complainant.find_by(id: metadata["complainant_id"]) if metadata
  end

  # title may change after investigation was created, so we retrieve from the
  # metadata stored at the time of creation
  def title(_user = nil)
    return self[:title] if self[:title] # older activities stored this in the database

    "Case logged: #{metadata['investigation']['title']}"
  end

  # We can now display only the complainant part conditionally when metadata is
  # present, but not older activities. In this case the entire activity text
  # is hidden. Where metadata is present, this method is needed for
  # compatibility with the display of other activity types where this is not
  # yet implemented.
  def can_display_all_data?(user)
    return true if self[:metadata].present? || investigation.complainant.blank?

    Pundit.policy(user, investigation).view_protected_details?
  end

  # Only used for old records prior to metadata implementation
  def restricted_title(user)
    title(user)
  end
end
