class CoronavirusRelatedForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :coronavirus_related, :boolean, default: :nil
end
