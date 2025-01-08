class AddTestReportsForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :add_another_test_report
  validates :add_another_test_report, presence: true
end
