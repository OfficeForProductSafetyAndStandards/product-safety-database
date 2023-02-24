class AuditActivity::Business::Add < AuditActivity::Base
  belongs_to :business, class_name: "::Business"

  def self.build_metadata(business, business_investigation)
    { business: business.attributes, investigation_business: business_investigation.attributes }
  end

  def metadata
    migrate_metadata_structure
  end

private

  def migrate_metadata_structure
    metadata = self[:metadata]

    return metadata if already_in_new_format?

    JSON.parse({
      "business" => business.attributes,
      "investigation_business" => {
        "relationship" => extract_relationship_from_body
      }
    }.to_json)
  end

  def extract_relationship_from_body
    body.match(/Role: \*\*(?<relationship>.*)\*\*/)["relationship"].delete("\\")
  end

  def already_in_new_format?
    self[:metadata]&.key?("business")
  end
end
