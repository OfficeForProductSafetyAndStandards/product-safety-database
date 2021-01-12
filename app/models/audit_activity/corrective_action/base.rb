class AuditActivity::CorrectiveAction::Base < AuditActivity::Base
  include ActivityAttachable
  with_attachments attachment: "attachment"

  belongs_to :business, optional: true, class_name: "::Business"
  belongs_to :product, class_name: "::Product"

  def corrective_action
    @corrective_action ||= begin
                             if metadata&.dig("corrective_action_id")
                               CorrectiveAction.find_by!(id: metadata["corrective_action_id"])
                             elsif attachment.attached?
                               attachment.blob.attachments
                                 .find_by(record_type: "CorrectiveAction")
                                 &.record
                             end
                           end
  end

  def activity_type
    "corrective action"
  end

  # Do not send investigation_updated mail when test result updated. This
  # overrides inherited functionality in the Activity model :(
  def notify_relevant_users; end
end
