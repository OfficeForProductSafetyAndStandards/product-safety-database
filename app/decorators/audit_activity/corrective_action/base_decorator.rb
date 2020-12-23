class AuditActivity::CorrectiveAction::BaseDecorator < ActivityDecorator
  decorates_association :product, with: ProductDecorator
  decorates_association :business, with: BusinessDecorator
  delegate :name, to: :product, prefix: true
  delegate :geographic_scope, :duration, :measure_type, :date_decided, :legislation, :geographic_scope, to: :corrective_action

  def trading_name
    corrective_action.business.trading_name
  end

  def date_decided
    corrective_action.date_decided.to_s(:govuk)
  end

  def measure_type
    CorrectiveAction.human_attribute_name("measure_type.#{corrective_action.measure_type}")
  end

  def duration
    CorrectiveAction.human_attribute_name("duration.#{corrective_action.duration}")
  end

  def document_filename
    corrective_action.document&.filename
  end

  def details
    corrective_action.details
  end
end
