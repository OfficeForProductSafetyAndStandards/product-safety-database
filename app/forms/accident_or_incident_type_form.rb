class AccidentOrIncidentTypeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :event_type, :string, default: nil

  validates :event_type,
            presence: true,
            inclusion: { in: AccidentOrIncident.event_types.values, message: "Select yes if you know when the accident or incident happened" }
end
