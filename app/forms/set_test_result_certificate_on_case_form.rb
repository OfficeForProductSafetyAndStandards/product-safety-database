class SetTestResultCertificateOnCaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :tso_certificate_reference_number, :string
  attribute :tso_certificate_issue_date, :govuk_date

  validates :tso_certificate_issue_date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true,
            recent_date: { on_or_before: false }

end
