class AccidentOrIncidentForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Dirty

  attribute :date, :govuk_date
  attribute :is_date_known, :boolean
  attribute :product_id
  attribute :severity
  attribute :severity_other
  attribute :usage
  attribute :additional_info
  attribute :type

  validates :is_date_known, inclusion: { in: [ true, false ] }
  validates :date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true,
            if: -> { is_date_known }
  validates :product_id, presence: true
  validates :severity, inclusion: { in: UnexpectedEvent.severities.values, message: I18n.t(".accident_or_incident_form.severity.inclusion") }
  validates :usage, inclusion: { in: UnexpectedEvent.usages.values, message: I18n.t(".accident_or_incident_form.usage.inclusion") }
  validates :severity_other, presence: true, if: -> { severity == "other" }

  ATTRIBUTES_FROM_ACCIDENT_OR_INCIDENT = %w[
    is_date_known
    severity
    severity_other
    additional_info
    usage
    product_id
    type
    date
  ].freeze

  def self.from(accident_or_incident)
    new(accident_or_incident.serializable_hash(only: ATTRIBUTES_FROM_ACCIDENT_OR_INCIDENT)).tap do |form|
      form.changes_applied
    end
  end
end
