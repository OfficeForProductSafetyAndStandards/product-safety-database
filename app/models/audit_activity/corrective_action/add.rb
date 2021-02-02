class AuditActivity::CorrectiveAction::Add < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action)
    { corrective_action: corrective_action.attributes, document: corrective_action.document_blob&.attributes }
  end

  def self.metadata_from_legacy_audit_activity(audit_activity)
    attributes = audit_activity.body.split("<br>").each_with_object({}) do |fragment, corrective_action_attributes|
      next if fragment.empty?

      case fragment
      when /Legislation: \*\*(.*)\*\*/
        corrective_action_attributes[:legislation] = Regexp.last_match(1)
      when /Date came into effect: \*\*(.*)\*\*/
        corrective_action_attributes[:decided_date] = Regexp.last_match(1)
      when /Type of measure: \*\*(.*)\*\*/
        corrective_action_attributes[:measure] = Regexp.last_match(1)
      when /Duration of action: \*\*(.*)\*\*/
        corrective_action_attributes[:duration] = Regexp.last_match(1)
      when /Geographic scopes: \*\*(.*)\*\*/
        corrective_action_attributes[:geographic_scopes] = Regexp.last_match(1)
      when /Attached|Product/
        next
      else
        corrective_action_attributes[:details] = fragment
      end
    end

    metadata = { corrective_action: attributes }
    metadata[:document] = audit_activity.attachment.attributes if audit_activity.attachment.attached?

    metadata
  end

  def email_update_text(viewer = nil)
    "Corrective action was added to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end

  def title(_viewing_user = nil)
    action_name = metadata.dig("corrective_action", "action")

    truncated_action = CorrectiveAction::TRUNCATED_ACTION_MAP[action_name.to_sym]
    return "#{truncated_action}: #{product.name}" unless action_name.inquiry.other?

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
