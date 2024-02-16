class AddLocationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :address_line_1, :string
  attribute :address_line_2, :string
  attribute :city, :string
  attribute :county, :string
  attribute :country, :string
  attribute :postal_code, :string
  attribute :business_id
  attribute :location_id

  validates :country, presence: true
end
