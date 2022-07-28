class ChangeCaseSummaryForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :summary

  validates :summary, presence: true, length: { maximum: 800 }
end
