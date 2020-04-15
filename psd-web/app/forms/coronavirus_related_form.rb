class CoronavirusRelatedForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :coronavirus_related, :boolean, default: nil

  validates :coronavirus_related,
            inclusion: { in: [true, false], message: "Select whether or not the case is related to the coronavirus outbreak" }
end
