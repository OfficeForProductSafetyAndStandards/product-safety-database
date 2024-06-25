class AccidentOrIncidentForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Dirty

  attr_accessor :date_year, :date_month, :date_day

  attribute :date
  attribute "date(1i)"
  attribute "date(2i)"
  attribute "date(3i)"

  attribute :is_date_known, :boolean
  attribute :investigation_product_id
  attribute :severity
  attribute :severity_other
  attribute :usage
  attribute :additional_info
  attribute :type

  validate  :is_date_known_inclusion
  validates :date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true,
            recent_date: { on_or_before: false },
            if: -> { is_date_known }
  validate  :presence_of_product
  validates :usage, inclusion: { in: UnexpectedEvent.usages.values, message: I18n.t(".accident_or_incident_form.usage.inclusion") }
  validates :severity_other, presence: true, if: -> { severity == "other" }
  validate  :severity_inclusion

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

  def initialize(attributes = {})
    super

    @date_year = attributes["date(1i)"]
    @date_month = attributes["date(2i)"]
    @date_day = attributes["date(3i)"]
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

private

  def set_date
    if @date_year.present? && @date_month.present? && @date_day.present?
      begin
        Date.new(@date_year.to_i, @date_month.to_i, @date_day.to_i)
      rescue ArgumentError
        { year: @date_year, month: @date_month, day: @date_day }
      end
    else
      { year: @date_year, month: @date_month, day: @date_day }
    end
  end
end
