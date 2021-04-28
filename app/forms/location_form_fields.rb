class LocationFormFields
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name
  attribute :address_line_1
  attribute :address_line_2
  attribute :city
  attribute :county
  attribute :postal_code
  attribute :country

  validates :name, presence: true
end
