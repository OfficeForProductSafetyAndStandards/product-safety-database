class AuditActivity::CorrectiveAction::Add < AuditActivity::CorrectiveAction::Base
  def self.from(corrective_action)
    super(corrective_action)
  end

  def self.possible_corrective_action_for(audit_activity)
    if (corrective_action = audit_activity.corrective_action)
      return corrective_action
    end

    corrective_actions =
      CorrectiveAction
        .where(investigation: audit_activity.investigation)
        .joins(investigation: :activities)
        .where.not(investigation: { activities: { type: AuditActivity::CorrectiveAction::Update.name } })
        .where(investigation: { activities: { type: AuditActivity::CorrectiveAction::Add.name } })
        .distinct

    corrective_actions = corrective_actions.reject { |ca| ca.document.attached? }

    if corrective_actions.one?
      corrective_action = corrective_actions.first
    else
      raise AuditActivity::CorrectiveAction::CouldNotDeterminCorrectiveAction
    end

    corrective_action
  end

  def self.populate_missing_fields(metadata, audit_activity)
    return unless (corrective_action = possible_corrective_action_for(audit_activity))

    metadata[:corrective_action][:legislation]      ||= corrective_action.legislation
    metadata[:corrective_action][:date_decided]     ||= corrective_action.date_decided
    metadata[:corrective_action][:measure_type]     ||= corrective_action.measure_type
    metadata[:corrective_action][:duration]         ||= corrective_action.duration
    metadata[:corrective_action][:geographic_scope] ||= corrective_action.geographic_scope
    metadata[:corrective_action][:id] = corrective_action.id

    metadata
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
        corrective_action_attributes[:measure_type] = Regexp.last_match(1)
      when /\ADuration of action: \*\*(.*)\*\*\z/
        corrective_action_attributes[:duration] = Regexp.last_match(1)
      when /\AGeographic scope: \*\*(.*)\*\*\z/
        corrective_action_attributes[:geographic_scope] = Regexp.last_match(1)
      when /\AAttached|\AProduct|\ABusiness responsible:/
        next
      else
        corrective_action_attributes[:details] ||= fragment.strip.presence
      end
    end

    metadata = { corrective_action: attributes }
    metadata[:document] = audit_activity.attachment.attributes if audit_activity.attachment.attached?

    populate_missing_fields(metadata, audit_activity)
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
