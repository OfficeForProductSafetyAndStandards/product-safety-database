class BusinessForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :relationship, default: ""
  attribute :other_relationship
  attribute :trading_name
  attribute :legal_name
  attribute :company_number
  attribute :primary_location, :location_form_params, default: LocationFormFields.new
  attribute :primary_contact, :contact_form_params, default: ContactFormFields.new

  validates :trading_name, presence: true
end
