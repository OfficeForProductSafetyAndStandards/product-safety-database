class AuditActivity::CorrectiveAction::BaseDecorator < ActivityDecorator
  decorates_association :product, with: ProductDecorator
  decorates_association :business, with: BusinessDecorator
end
