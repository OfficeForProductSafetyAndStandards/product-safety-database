module SupportPortal
  class AddRoleForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveRecord::AttributeAssignment

    attribute :role_name, :string
    attribute :custom_role_name, :string

    validates :role_name, presence: { message: "Select a role" }
    validates :custom_role_name, presence: { message: "Enter a role name" }, if: -> { role_name == "other" }
  end
end
