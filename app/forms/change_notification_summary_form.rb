class ChangeNotificationSummaryForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :summary

  validates :summary, length: { maximum: 10_000 }
end
