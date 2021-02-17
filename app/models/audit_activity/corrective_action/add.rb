class AuditActivity::CorrectiveAction::Add < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action)
    { corrective_action: corrective_action.attributes, document: corrective_action.document_blob&.attributes }
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

  def self.migrate_geographic_scopes!(audit_activity)
    return unless (geographic_scope = audit_activity.metadata.dig("corrective_action", "geographic_scope"))

    audit_activity.metadata["corrective_action"]["geographic_scopes"] = [CorrectiveAction::GEOGRAPHIC_SCOPES_MIGRATION_MAP[geographic_scope]]
    audit_activity.save!
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

  def title(_viewing_user = nil)
    action_name = metadata.dig("corrective_action", "action")
    return unless action_name

    if (truncated_action = CorrectiveAction::TRUNCATED_ACTION_MAP[action_name.to_sym])
      return "#{truncated_action}: #{product.name}" unless action_name.inquiry.other?
    end

    metadata.dig("corrective_action", "other_action")
  end

  def corrective_action
    @corrective_action ||= begin
                             if (corrective_action_id = metadata&.dig("corrective_action", "id"))
                               CorrectiveAction.find_by!(id: corrective_action_id)
                             else
                               super
                             end
                           end
  end

private

  def subtitle_slug
    "Corrective action recorded"
  end
end
