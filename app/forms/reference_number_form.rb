class ReferenceNumberForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :has_complainant_reference, :boolean
  attribute :complainant_reference, :string

  validates :has_complainant_reference, inclusion: { in: [true, false] }
  validates :complainant_reference, presence: true, if: -> { has_complainant_reference }
end
