class AuditActivity::CorrectiveAction::BaseDecorator < ActivityDecorator
  include Investigations::CorrectiveActionsHelper

  decorates_association :product, with: ProductDecorator
  decorates_association :business, with: BusinessDecorator
  delegate :name, to: :product, prefix: true
  delegate :details, :geographic_scope, :duration, :measure_type, :date_decided, :legislation, :geographic_scope, to: :corrective_action

  delegate :trading_name, to: :business

  def date_decided
    @date_decided ||= Date.parse(metadata.dig("updates", "date_decided", 1)).to_s(:govuk)
  end

  def legislation
    metadata.dig("updates", "legislation", 1)
  end

  def details
    metadata.dig("updates", "details", 1)
  end

  def measure_type
    CorrectiveAction.human_attribute_name("measure_type.#{metadata.dig('updates', 'measure_type', 1)}")
  end

  def duration
    CorrectiveAction.human_attribute_name("duration.#{metadata.dig('updates', 'duration', 1)}")
  end

  def geographic_scope
    metadata.dig("updates", "geographic_scope", 1)
  end

  def document_filename
    corrective_action.document&.filename
  end
end
