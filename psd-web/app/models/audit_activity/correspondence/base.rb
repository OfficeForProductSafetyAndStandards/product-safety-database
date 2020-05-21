class AuditActivity::Correspondence::Base < AuditActivity::Base
  belongs_to :correspondence

  private_class_method def self.from(correspondence, investigation, body = nil)
    create(
      body: body || sanitize_text(correspondence.details),
      source: UserSource.new(user: User.current),
      investigation: investigation,
      title: correspondence.overview,
      correspondence: correspondence
    )
  end

  def can_display_all_data?(user)
    correspondence.can_be_displayed?(user)
  end
end
