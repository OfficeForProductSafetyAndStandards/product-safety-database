class ChangeCaseVisibilityForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :case_type
  attribute :old_visibility
  attribute :new_visibility
  attribute :rationale

  validates_inclusion_of :new_visibility, in: %w[restricted unrestricted]
  validate :new_visibility_is_different

  def self.from(investigation)
    old_visibility = investigation.is_private? ? "restricted" : "unrestricted"
    new(case_type: "case", old_visibility:)
  end

private

  def new_visibility_is_different
    errors.add(:new_visibility, :same_as_existing, case_type:, visibility: new_visibility) if new_visibility == old_visibility
  end
end
