class SupportingInformationTypeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  MAIN_TYPES = {
    accident_or_incident: "Accident or Incident",
    comment: "Comment",
    corrective_action: "Corrective action",
    correspondence: "Correspondence",
    image: "Image",
    testing_result: "Test result",
    risk_assessment: "Risk assessment"
  }.freeze
  GENERIC_TYPE = { generic_information: "Other document or attachment" }.freeze
  AVAILABLE_TYPES = MAIN_TYPES.merge(GENERIC_TYPE)

  attribute :type

  validates_presence_of :type
end
