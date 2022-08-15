class ReferenceNumberForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :has_complainant_reference, :boolean
  attribute :complainant_reference, :string

  validates :add_complainant_reference, presence: true
end
