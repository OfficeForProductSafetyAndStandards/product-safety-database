class InvestigationSerializer < ActiveModel::Serializer
  attributes :type, :owner_id, :creator_id, :hazard_type,
             :description, :product_category, :is_closed, :updated_at, :created_at,
             :pretty_id, :hazard_description, :non_compliant_reason,
             :complainant_reference, :risk_level, :title, :user_title

  attribute :last_change_at do
    latest_activity_date = object.activities.pluck(:created_at).max
    [latest_activity_date, object.updated_at, object.created_at].compact.max
  end

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
