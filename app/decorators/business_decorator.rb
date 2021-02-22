class BusinessDecorator < ApplicationDecorator
  delegate_all
  decorates_association :investigations

  def to_csv
    self.class.attributes_for_export.map { |key| send(key) }
  end
end
