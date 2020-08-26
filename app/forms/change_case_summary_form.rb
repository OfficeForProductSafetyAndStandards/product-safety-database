class ChangeCaseSummaryForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :summary

  validates_presence_of :summary
  validates :summary, length: { maximum: 10_000 }
end
