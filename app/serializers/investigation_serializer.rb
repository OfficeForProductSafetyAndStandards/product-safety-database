class InvestigationSerializer < ActiveModel::Serializer
  attributes :type, :owner_id, :creator_id, :hazard_type,
             :description, :product_category, :is_closed, :updated_at, :created_at,
             :pretty_id, :hazard_description, :reported_reason, :non_compliant_reason,
             :complainant_reference, :risk_level, :title, :user_title

  attribute :creator_user do
    object.creator_user&.id
  end

  attribute :creator_team do
    object.creator_team&.id
  end

  has_many :businesses, serializer: BusinessSerializer
  has_many :products, serializer: ProductSerializer
  attribute :team_ids_with_access do
    teams = object.teams_with_read_only_access.or(object.teams_with_edit_access)
    teams.pluck(:id)
  end
end
