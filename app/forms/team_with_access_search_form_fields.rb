class TeamWithAccessSearchFormFields
  include ActiveModel::Model
  include ActiveModle::Attributes

  attribute :other_team_with_access, :boolean
  attribute :other_team_with_access_id
  attribute :id
end
