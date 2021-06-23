class AlertForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Dirty

  attribute :summary
  attribute :description
  attribute :investigation_url

  validate :summary_validation
  validate :description_validation

  def default_summary
    "Product safety alert: "
  end

  def default_description
    "\r\n\r\n\r\nMore details can be found on the case page: #{investigation_url}"
  end

  def summary_validation
    if summary.empty? || summary == default_summary
      errors.add(:summary, :required, message: "Enter a summary")
    end
  end

  def description_validation
    if description.empty? || description == default_description
      errors.add(:description, :required, message: "Enter an alert")
    end
  end
end
