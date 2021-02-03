class AccidentOrIncidentForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :date, :govuk_date
  attribute :is_date_known
  attribute :product_id
  attribute :severity
  attribute :severity_other
  attribute :usage
  attribute :additional_info
  attribute :event_type

  validates :is_date_known, presence: true
  validates :product_id, presence: true
  validates :severity, presence: true
  validates :usage, presence: true
  validates :date, presence: true, if: -> { is_date_known == 'yes' }
  validates :severity_other, presence: true, if: -> { severity == 'other' }
  validates :event_type, presence: true
end
