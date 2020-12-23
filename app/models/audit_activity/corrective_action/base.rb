class AuditActivity::CorrectiveAction::Base < AuditActivity::Base
  include ActivityAttachable
  with_attachments attachment: "attachment"

  belongs_to :business, optional: true, class_name: "::Business"
  belongs_to :product, class_name: "::Product"

  def activity_type
    "corrective action"
  end
end
