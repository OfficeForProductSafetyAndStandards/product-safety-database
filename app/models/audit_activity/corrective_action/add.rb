class AuditActivity::CorrectiveAction::Add < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action)
    { corrective_action: corrective_action.attributes, document: corrective_action.document_blob&.attributes }
  end

  def self.migrate_legacy_audit_activity(audit_activity)
    audit_activity.body.split("<br>").each do |fragment|
      case fragment
      when /Legislation: \*\*(.*)\*\*/

      when /Date came into effect: \*\*(.*)\*\*/
      when /Type of measure: \*\*(.*)\*\*/
      when /Duration of action: \*\*(.*)\*\*/
      when /Geographic scopes: \*\*(.*)\*\*/
      end
    end
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
