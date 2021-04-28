class ContactFormFields
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name
  attribute :email
  attribute :phone_number
  attribute :job_title
end
