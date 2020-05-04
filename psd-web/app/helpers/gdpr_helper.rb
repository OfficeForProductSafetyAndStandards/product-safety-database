module GdprHelper
  def can_be_displayed?(document, parent)
    attachment_creator = User.find_by(id: document.metadata[:created_by])
    child_is_visible = UserSource.new(user: attachment_creator).user_has_gdpr_access? || !document.metadata[:has_consumer_info]
    parent_forces_to_be_visible = parent.respond_to?(:child_should_be_displayed?) && parent.child_should_be_displayed?
    child_is_visible || parent_forces_to_be_visible
  end

  def document_restricted_title
    "Attachment restricted"
  end

  def document_restricted_body
    "This attachment is restricted because it has been marked as containing GDPR protected data. " \
      "Contact the case owner if you need access."
  end
end
