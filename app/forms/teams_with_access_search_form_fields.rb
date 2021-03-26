class TeamsWithAccessSearchFormFields
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :other_team_with_access, :boolean
  attribute :id, default: []

  def initialize(*args)
    super

    self.id = [] unless other_team_with_access
    id.reject!(&:blank?)
  end
end
