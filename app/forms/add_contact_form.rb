class AddContactForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :name, :string
  attribute :job_title, :string
  attribute :phone_number, :string
  attribute :email, :string
  attribute :business_id
  attribute :contact_id
end
