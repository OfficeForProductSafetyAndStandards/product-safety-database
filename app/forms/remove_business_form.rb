class RemoveBusinessForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :remove, :boolean
  alias_method :remove?, :remove
  attribute :reason

  validates_inclusion_of :remove, in: [true, false]
  validates_presence_of :reason, if: :remove?
end
