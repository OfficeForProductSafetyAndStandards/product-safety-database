class AccidentOrIncidentForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Dirty

  attribute :date, :govuk_date
  attribute :is_date_known, :boolean
  attribute :investigation_product_id
  attribute :severity
  attribute :severity_other
  attribute :usage
  attribute :additional_info
  attribute :type

  validates :date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true,
            recent_date: { on_or_before: false },
            if: -> { is_date_known }
  validates :usage, inclusion: { in: UnexpectedEvent.usages.values, message: I18n.t(".accident_or_incident_form.usage.inclusion") }
  validates :severity_other, presence: true, if: -> { severity == "other" }
  validate  :severity_inclusion
  validate  :is_date_known_inclusion
  validate  :presence_of_product

  ATTRIBUTES_FROM_ACCIDENT_OR_INCIDENT = %w[
    is_date_known
    severity
    severity_other
    additional_info
    usage
    investigation_product_id
    type
    date
  ].freeze

  def self.from(accident_or_incident)
    new(accident_or_incident.serializable_hash(only: ATTRIBUTES_FROM_ACCIDENT_OR_INCIDENT)).tap(&:changes_applied)
  end

  def severity_inclusion
    errors.add(:severity, :inclusion, type: type.downcase) unless UnexpectedEvent.severities.value?(severity)
  end

  def is_date_known_inclusion
    errors.add(:is_date_known, :inclusion, type: type.downcase) unless [true, false].include?(is_date_known)
  end

  def presence_of_product
    errors.add(:investigation_product_id, :blank, type: type.downcase) if investigation_product_id.blank?
  end
end
