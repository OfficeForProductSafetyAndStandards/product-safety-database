class ReportedReasonForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  validates :reported_reason, presence: true
  attribute :reported_reason

  def self.from(investigation)
    new(reported_reason: investigation.reported_reason)
  end
end
