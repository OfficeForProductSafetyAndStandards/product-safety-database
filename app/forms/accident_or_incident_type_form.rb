class AccidentOrIncidentTypeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :type, :string, default: nil

  validates :type,
            inclusion: { in: ["accident", "incident"], message: "Select something" }
end
