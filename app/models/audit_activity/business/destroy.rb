class AuditActivity::Business::Destroy < AuditActivity::Base
  belongs_to :business, class_name: "::Business"

  def self.build_metadata(business, reason)
    { reason:, business: business.attributes }
  end

  def metadata
    migrate_metadata_structure
  end

private

  def subtitle_slug
    "Business removed"
  end

  def migrate_metadata_structure
    metadata = self[:metadata]

    return metadata if already_in_new_format?

    JSON.parse({ business: business.attributes }.to_json)
  end

  def already_in_new_format?
    self[:metadata]&.key?("business")
  end
end
