class AuditActivity::CorrectiveAction::BaseDecorator < ActivityDecorator
  include Investigations::CorrectiveActionsHelper

  decorates_association :business, with: BusinessDecorator
  delegate :details, :duration, :measure_type, :date_decided, :legislation, :geographic_scope, to: :corrective_action

  delegate :trading_name, to: :business

  def document_filename
    attachment&.filename
  end
end
