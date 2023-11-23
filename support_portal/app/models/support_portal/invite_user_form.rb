module SupportPortal
  class InviteUserForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveRecord::AttributeAssignment

    attribute :name, :string
    attribute :email, :string
    attribute :team_id, :string

    validates :email, presence: { message: "Enter an email address" }
    validates :team_id, presence: { message: "Select a team" }
  end
end
