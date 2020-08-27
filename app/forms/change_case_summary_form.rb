class ChangeCaseSummaryForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :summary

  validates :summary, presence: true, length: { maximum: 10_000 }
end
