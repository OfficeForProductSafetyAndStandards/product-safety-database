class CorrespondenceTypeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  AVAILABLE_TYPES = {
    email: "Record email",
    phone_call: "Record phone call"
  }.freeze

  attribute :type

  validates_presence_of :type
end
