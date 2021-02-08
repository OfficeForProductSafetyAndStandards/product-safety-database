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

  validates :is_date_known, inclusion: { in: %w[yes no], message: I18n.t(".accident_or_incident_form.is_date_know.inclusion") }
  validates :date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true,
            if: -> { is_date_known == "yes" }
  validates :product_id, presence: true
  validates :severity, inclusion: { in: UnexpectedEvent.severities.values, message: I18n.t(".accident_or_incident_form.severity.inclusion") }
  validates :usage, inclusion: { in: UnexpectedEvent.usages.values, message: I18n.t(".accident_or_incident_form.usage.inclusion") }
  validates :severity_other, presence: true, if: -> { severity == "other" }
end
