class SupportingInformationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  AVAILABLE_TYPES = {
    comment: "Comment",
    corrective_action: "Corrective action",
    correspondence: "Correspondence",
    image: "Image",
    testing_result: "Test result",
    generic_information: "Other document or attachment"
  }.freeze

  attribute :type

  validates_presence_of :type
end
