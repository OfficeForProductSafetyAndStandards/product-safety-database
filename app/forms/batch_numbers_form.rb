class BatchNumbersForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :batch_numbers, :string
end
