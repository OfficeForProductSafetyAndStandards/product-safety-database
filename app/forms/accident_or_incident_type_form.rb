class AccidentOrIncidentTypeForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :type, :string, default: nil

  validates :type,
            inclusion: { in: %w[Accident Incident], message: I18n.t(".accident_or_incident_type_form.type.inclusion") }
end
