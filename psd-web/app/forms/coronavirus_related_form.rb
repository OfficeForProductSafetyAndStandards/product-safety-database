class CoronavirusRelatedForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :coronavirus_related, :boolean, default: :nil

  validates_presence_of :coronavirus_related, message: "Select whether or not the case is related to the coronavirus outbreak"
end
