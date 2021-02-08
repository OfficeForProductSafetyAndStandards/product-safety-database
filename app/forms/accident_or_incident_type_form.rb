class AccidentOrIncidentTypeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :event_type, :string, default: nil

  validates :event_type,
            inclusion: { in: %w[accident incident], message: "Select the type of information you're adding" }
end
