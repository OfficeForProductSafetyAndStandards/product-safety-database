class TeamsWithAccessSearchFormFields
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :other_team_with_access, :boolean
  attribute :other_team_with_access_id
  attribute :id

  def initialize(*args)
    super

    self.other_team_with_access_id = other_team_with_access_id.presence
  end

  def ids
    @ids ||= [id, other_team_with_access ? other_team_with_access_id : nil].compact!
  end
end
