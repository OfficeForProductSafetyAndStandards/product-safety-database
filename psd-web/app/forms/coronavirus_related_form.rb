class CoronavirusRelatedForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :coronavirus_related, default: :nil

  validates :coronavirus_related,
            inclusion: { in: %w(true false), message: "Select whether or not the case is related to the coronavirus outbreak" }
end
