class TeamsWithAccessSearchFormFields
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :my_team
  attribute :id, default: []

  def initialize(*args)
    super

    id.reject!(&:blank?)
  end

  def ids
    @ids ||= my_team.present? ? id + [my_team] : id
  end
end
