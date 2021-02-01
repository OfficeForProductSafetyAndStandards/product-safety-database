class AccidentOrIncidentTypeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :event_type, :string, default: nil

  validates :event_type,
            inclusion: { in: ["accident", "incident"], message: "Select accident or incident" }
end
