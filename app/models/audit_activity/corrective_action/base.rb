class AuditActivity::CorrectiveAction::Base < AuditActivity::Base
  include ActivityAttachable
  with_attachments attachment: "attachment"

  belongs_to :business, optional: true, class_name: "::Business"
  belongs_to :investigation_product, class_name: "::InvestigationProduct"

  def corrective_action
    if attachment.attached?
      attachment.blob.attachments.find_by(record_type: "CorrectiveAction")&.record
    elsif investigation.corrective_actions.one?
      investigation.corrective_actions.first
    end
  end

  def activity_type
    "corrective action"
  end
end
