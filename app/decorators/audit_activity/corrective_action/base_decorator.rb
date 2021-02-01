class AuditActivity::CorrectiveAction::BaseDecorator < ActivityDecorator
  include Investigations::CorrectiveActionsHelper

  decorates_association :product, with: ProductDecorator
  decorates_association :business, with: BusinessDecorator
  delegate :name, to: :product, prefix: true
  delegate :details, :geographic_scope, :duration, :measure_type, :date_decided, :legislation, :geographic_scope, to: :corrective_action

  delegate :trading_name, to: :business

  def attached_image?
    attachment&.image?
  end

  def document_filename
    attachment&.filename
  end
end
