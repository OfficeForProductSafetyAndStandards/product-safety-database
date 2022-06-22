class SupportingInformationTypeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  MAIN_TYPES = {
    accident_or_incident: "Accident or incident",
    corrective_action: "Corrective action",
    correspondence: "Correspondence",
    testing_result: "Test result",
    risk_assessment: "Risk assessment",
    generic_information: "Other document or attachment"
  }.freeze
  IMAGE_TYPE = { image: "Case image", }.freeze
  AVAILABLE_TYPES = MAIN_TYPES.merge(IMAGE_TYPE)

  attribute :type
  attribute :options

  validates_presence_of :type
  validates_presence_of :options
end
