class AuditActivity::Business::Add < AuditActivity::Base
  belongs_to :business, class_name: "::Business"

  def self.build_metadata(business, business_investigation)
    { business: business.attributes, investigation_business: business_investigation.attributes }
  end

  def self.from(*)
    raise "Deprecated - use AddBusinessToCase.call instead"
  end

  def migrate_to_metadata
    update!(
      metadata: {
        business: business.attributes,
        investigation_business: {
          relationship: body.match(/Role: \*\*(?<relationship>.*)\*\*/)["relationship"].delete("\\")
        }
      }
    )
  end

private

  def notify_relevant_users; end
end
