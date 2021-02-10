class AuditActivity::CorrectiveAction::Add < AuditActivity::CorrectiveAction::Base
  def self.from(corrective_action)
    super(corrective_action)
  end

  def self.metadata_from_legacy_audit_activity(audit_activity)
    attributes = audit_activity.body.split("<br>").each_with_object(details: nil) do |fragment, corrective_action_attributes|
      next if fragment.empty?

      case fragment
      when /\ALegislation: \*\*(.*)\*\*\z/
        corrective_action_attributes[:legislation] = Regexp.last_match(1)
      when /\ADate came into effect: \*\*(.*)\*\*\z/
        corrective_action_attributes[:date_decided] = Date.parse(Regexp.last_match(1))
      when /\AType of measure: \*\*(.*)\*\*\z/
        corrective_action_attributes[:measure] = Regexp.last_match(1)
      when /\ADuration of action: \*\*(.*)\*\*\z/
        corrective_action_attributes[:duration] = Regexp.last_match(1)
      when /\AGeographic scope: \*\*(.*)\*\*\z/
        corrective_action_attributes[:geographic_scopes] = Regexp.last_match(1)
      when /\AAttached|\AProduct|\ABusiness responsible:/
        next
      else
        corrective_action_attributes[:details] ||= fragment.strip.presence
      end
    end

    metadata = { corrective_action: attributes }
    metadata[:document] = audit_activity.attachment.attributes if audit_activity.attachment.attached?

    metadata
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
