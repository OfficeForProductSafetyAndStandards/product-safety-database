class SupportingInformationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  AVAILABLE_TYPES = {
    comment: "Comment or case note",
    corrective_action: "Corrective action",
    correspondence: "Correspondence",
    image: "Image",
    testing_result: "Test result",
    generic_information: "Other document or attachment"
  }

  attribute :type

  validates_presence_of :type
end
