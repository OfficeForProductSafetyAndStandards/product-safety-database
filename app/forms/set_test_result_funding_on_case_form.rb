class SetTestResultFundingOnCaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :opss_funded
  validates_inclusion_of :opss_funded, in: %w[true false], message: "Select yes if the test was funded under the OPSS Sampling Protocol"

  def is_opss_funded?
    opss_funded == "true"
  end
end
