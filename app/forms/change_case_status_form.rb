class ChangeCaseStatusForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :case_type
  attribute :old_status
  attribute :new_status
  attribute :rationale

  validates_inclusion_of :new_status, in: %w[open closed]
  validate :new_status_is_different

  def self.from(investigation)
    old_status = investigation.is_closed? ? "closed" : "open"
    new(case_type: "notification", old_status:)
  end

private

  def new_status_is_different
    errors.add(:new_status, :same_as_existing, case_type:, status: new_status) if new_status == old_status
  end
end
