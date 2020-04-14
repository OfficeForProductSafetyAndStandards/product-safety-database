class WhyReportingForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :hazard_type
  attribute :hazard_description
  attribute :non_compliant_reason
  attribute :reported_reason_unsafe, :boolean, default: false
  attribute :reported_reason_non_compliant, :boolean, default: false
  attribute :reported_reason_safe_and_compliant, :boolean, default: false

  validates :reported_reason, presence: true

  def reported_reason
    @reported_reason ||= case [reported_reason_unsafe, reported_reason_non_compliant, reported_reason_safe_and_compliant]
                         when [true, false, false] then :unsafe
                         when [false, true, false] then :non_compliant
                         when [false, false, true] then :safe_and_compliant
                         end
  end
end
