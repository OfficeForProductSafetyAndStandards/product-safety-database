class AuditActivity::CorrectiveAction::Base < AuditActivity::Base
  include ActivityAttachable
  with_attachments attachment: "attachment"

  belongs_to :business, optional: true
  belongs_to :product

  private_class_method def self.from(corrective_action)
    activity = self.create(
      title: corrective_action.summary,
      body: self.build_body(corrective_action),
      source: UserSource.new(user: User.current),
      investigation: corrective_action.investigation,
      business: corrective_action.business,
      product: corrective_action.product
    )
    activity.attach_blob corrective_action.documents.first.blob if corrective_action.documents.attached?
  end

  def self.build_body(corrective_action)
    body = ""
    body += "Product: **#{self.sanitize_text corrective_action.product.name}**<br>" if corrective_action.product.present?
    body += "Legislation: **#{self.sanitize_text corrective_action.legislation}**<br>" if corrective_action.legislation.present?
    body += "Business responsible: **#{self.sanitize_text corrective_action.business.trading_name}**<br>" if corrective_action.business.present?
    body += "Date came into effect: **#{corrective_action.date_decided.strftime('%d/%m/%Y')}**<br>" if corrective_action.date_decided.present?
    body += "Type of measure: **#{CorrectiveAction.human_attribute_name("measure_type.#{corrective_action.measure_type}")}**<br>"
    body += "Duration of action: **#{CorrectiveAction.human_attribute_name("duration.#{corrective_action.duration}")}**<br>"
    body += "Geographic scope: **#{corrective_action.geographic_scope}**<br>"
    body += "Attached: **#{self.sanitize_text corrective_action.documents.first.filename}**<br>" if corrective_action.documents.attached?
    body += "<br>#{self.sanitize_text corrective_action.details}" if corrective_action.details.present?
    body
  end

  def activity_type
    "corrective action"
  end
end
