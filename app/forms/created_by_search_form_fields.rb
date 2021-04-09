class CreatedBySearchFormFields
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :someone_else, :boolean
  alias_method :someone_else?, :someone_else
  attribute :my_team, :boolean
  alias_method :my_team?, :my_team
  attribute :me, :boolean
  alias_method :me?, :me
  attribute :id

  def initialize(*args)
    super

    self.id = nil unless someone_else?
    self.id = nil if id.blank?
  end
end
