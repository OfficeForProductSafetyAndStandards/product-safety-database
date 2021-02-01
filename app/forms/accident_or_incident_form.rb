class AccidentOrIncidentForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :date
  attribute :is_date_known
  attribute :product
  attribute :severity
  attribute :severity_other
  attribute :usage
  attribute :additional_info
  attribute :event_type

  validates :is_date_known, presence: true
  validates :product, presence: true
  validates :severity, presence: true
  validates :usage, presence: true
  validates :date, presence: true, if: -> { is_date_known }
  validates :severity_other, presence: true, if: -> { severity == 'other' }
  validates :event_type, presence: true
end
