class AuditActivity::Business::Destroy < AuditActivity::Base
  belongs_to :business, class_name: "::Business"

  def self.build_metadata(business, reason)
    { reason: reason, business: business.attributes }
  end

  def self.from(_business, _investigation)
    raise "Deprecated - use RemoveBusinessFromCase.call instead"
  end

private

  def subtitle_slug
    "Business removed"
  end

  def notify_relevant_users; end

  def migrate_metadata_structure
    metadata = self[:metadata]

    return metadata if already_in_new_format?

    # { business  }
  end

  def already_in_new_format?
    self[:metadata]&.key?("business")
  end
end
