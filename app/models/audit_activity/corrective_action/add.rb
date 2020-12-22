class AuditActivity::CorrectiveAction::Add < AuditActivity::CorrectiveAction::Base
  def self.from(_corrective_action)
    raise "Deprecated - use AddCorrectiveActionToCase.call instead"
  end

  def email_update_text(viewer = nil)
    "Corrective action was added to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end

  # Returns the actual CorrectiveAction record.
  #
  # This is a hack, as there is currently no direct association between the
  # AuditActivity record and the corrective action record it is about. So the only
  # way to retrieve this is by relying upon our current behaviour of attaching the
  # same actual file to all of the AuditActivity, Investigation and CorrectiveAction records.
  #
  # If no file was associated with the corrective action, this fails.
  def corrective_action
    if attachment.attached?
      attachment.blob.attachments
        .find_by(record_type: "CorrectiveAction")
        &.record
    end
  end

private

  def subtitle_slug
    "Corrective action recorded"
  end
end
